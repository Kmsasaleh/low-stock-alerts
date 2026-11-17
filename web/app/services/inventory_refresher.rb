# frozen_string_literal: true

class InventoryRefresher
  class Error < StandardError; end

  QUERY = <<~GRAPHQL
    query($id: ID!) {
      inventoryItem(id: $id) {
        tracked
        variants(first: 10) {
          nodes {
            id
            inventoryQuantity
          }
        }
      }
    }
  GRAPHQL

  class << self
    def call(shop:, inventory_item_id:, client: nil)
      return new(shop: shop, client: client).call(inventory_item_id) if client

      shop.with_shopify_session do |session|
        admin_client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)
        new(shop: shop, client: admin_client).call(inventory_item_id)
      end
    end
  end

  def initialize(shop:, client:)
    @shop = shop
    @client = client
  end

  def call(inventory_item_id)
    item = fetch(inventory_item_id)
    return 0 if item.nil? || !item["tracked"]

    item.dig("variants", "nodes").sum do |node|
      @shop.variants
        .where(shopify_gid: node["id"])
        .update_all(inventory_quantity: node["inventoryQuantity"].to_i, updated_at: Time.current)
    end
  end

  private

  def fetch(inventory_item_id)
    response = @client.query(query: QUERY, variables: { id: "gid://shopify/InventoryItem/#{inventory_item_id}" })
    errors = response.body["errors"]
    raise Error, "inventoryItem query failed: #{errors}" if errors

    response.body.dig("data", "inventoryItem")
  end
end
