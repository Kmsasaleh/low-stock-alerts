# Fetches every inventory-tracked, non-gift-card variant in the shop.
# Follows cursor pagination until Shopify reports no more pages.
class InventoryFetcher
  PAGE_SIZE = 100

  QUERY = <<~GRAPHQL
    query($cursor: String) {
      productVariants(first: #{PAGE_SIZE}, after: $cursor) {
        nodes {
          id
          title
          sku
          inventoryQuantity
          product { id title isGiftCard }
          inventoryItem { tracked }
        }
        pageInfo { hasNextPage endCursor }
      }
    }
  GRAPHQL

  def self.call(session:)
    new(session).call
  end

  def initialize(session)
    @client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
  end

  def call
    variants = []
    cursor = nil

    loop do
      response = @client.query(query: QUERY, variables: { cursor: cursor })
      body = response.body
      raise "Shopify GraphQL error: #{body['errors']}" if body["errors"]

      page = body.dig("data", "productVariants")
      variants.concat(page["nodes"].select { |v| trackable?(v) })

      break unless page.dig("pageInfo", "hasNextPage")
      cursor = page.dig("pageInfo", "endCursor")
    end

    variants
  end

  private

  def trackable?(variant)
    !variant.dig("product", "isGiftCard") && variant.dig("inventoryItem", "tracked")
  end
end
