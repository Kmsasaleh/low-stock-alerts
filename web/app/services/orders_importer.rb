# frozen_string_literal: true

class OrdersImporter
  ORDERS_PAGE_SIZE = 25
  LINE_ITEMS_PAGE_SIZE = 25

  QUERY = <<~GRAPHQL.freeze
    query($cursor: String, $search: String) {
      orders(first: #{ORDERS_PAGE_SIZE}, after: $cursor, query: $search, sortKey: CREATED_AT) {
        nodes {
          createdAt
          lineItems(first: #{LINE_ITEMS_PAGE_SIZE}) {
            nodes {
              id
              currentQuantity
              variant { id }
            }
            pageInfo { hasNextPage }
          }
        }
        pageInfo { hasNextPage endCursor }
      }
    }
  GRAPHQL

  class << self
    def call(shop:, session:, since: 60.days.ago)
      new(shop, session, since).call
    end
  end

  def initialize(shop, session, since)
    @shop = shop
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
    @search = "created_at:>=#{since.to_date.iso8601}"
    @variant_ids = shop.variants.pluck(:shopify_gid, :id).to_h
  end

  def call
    rows = []
    each_order { |order| rows.concat(rows_for(order)) }
    return 0 if rows.empty?

    SaleLine.upsert_all(rows, unique_by: [:shop_id, :shopify_line_item_id])
    rows.size
  end

  private

  def each_order
    cursor = nil
    loop do
      body = @client.query(query: QUERY, variables: { cursor: cursor, search: @search }).body
      raise "Shopify GraphQL error: #{body["errors"]}" if body["errors"]

      page = body.dig("data", "orders")
      page["nodes"].each { |order| yield(order) }
      break unless page.dig("pageInfo", "hasNextPage")

      cursor = page.dig("pageInfo", "endCursor")
    end
  end

  def rows_for(order)
    if order.dig("lineItems", "pageInfo", "hasNextPage")
      Rails.logger.warn("[OrdersImporter] order has over #{LINE_ITEMS_PAGE_SIZE} line items; extras skipped")
    end

    order.dig("lineItems", "nodes").filter_map do |item|
      variant_id = @variant_ids[item.dig("variant", "id")]
      next if variant_id.nil? || item["currentQuantity"].to_i <= 0

      {
        shop_id: @shop.id,
        variant_id: variant_id,
        shopify_line_item_id: item["id"],
        quantity: item["currentQuantity"],
        sold_at: order["createdAt"],
      }
    end
  end
end
