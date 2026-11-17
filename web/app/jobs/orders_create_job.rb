# frozen_string_literal: true

class OrdersCreateJob < ActiveJob::Base
  TOPIC = "orders/create"

  def perform(shop_domain:, webhook_id:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)
    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    ActiveRecord::Base.transaction do
      next unless ProcessedWebhook.claim(webhook_id: webhook_id, topic: TOPIC, shop_domain: shop_domain)

      rows = sale_line_rows(shop, webhook)
      SaleLine.upsert_all(rows, unique_by: [:shop_id, :shopify_line_item_id]) if rows.any?
    end
  end

  private

  def sale_line_rows(shop, order)
    items = Array(order["line_items"])
    gids = items.filter_map { |item| variant_gid(item["variant_id"]) }
    variant_ids = shop.variants.where(shopify_gid: gids).pluck(:shopify_gid, :id).to_h

    items.filter_map do |item|
      variant_id = variant_ids[variant_gid(item["variant_id"])]
      next if variant_id.nil? || item["quantity"].to_i <= 0

      {
        shop_id: shop.id,
        variant_id: variant_id,
        shopify_line_item_id: "gid://shopify/LineItem/#{item["id"]}",
        quantity: item["quantity"].to_i,
        sold_at: order["created_at"],
      }
    end
  end

  def variant_gid(numeric_id)
    numeric_id && "gid://shopify/ProductVariant/#{numeric_id}"
  end
end
