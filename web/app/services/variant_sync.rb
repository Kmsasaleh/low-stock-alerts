# frozen_string_literal: true

class VariantSync
  def self.call(shop:, session:)
    new(shop, session).call
  end

  def initialize(shop, session)
    @shop = shop
    @session = session
  end

  def call
    rows = InventoryFetcher.call(session: @session).map { |variant| row_for(variant) }
    return 0 if rows.empty?

    Variant.upsert_all(rows, unique_by: [:shop_id, :shopify_gid])
    rows.size
  end

  private

  def row_for(variant)
    {
      shop_id: @shop.id,
      shopify_gid: variant["id"],
      product_title: variant.dig("product", "title"),
      variant_title: variant["title"],
      sku: variant["sku"],
      inventory_quantity: variant["inventoryQuantity"] || 0,
    }
  end
end
