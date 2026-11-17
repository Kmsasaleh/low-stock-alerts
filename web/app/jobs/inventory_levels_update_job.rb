# frozen_string_literal: true

class InventoryLevelsUpdateJob < ActiveJob::Base
  TOPIC = "inventory_levels/update"

  retry_on InventoryRefresher::Error, ShopifyAPI::Errors::HttpResponseError, wait: :polynomially_longer, attempts: 5

  def perform(shop_domain:, webhook_id:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)
    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")
      return
    end

    inventory_item_id = webhook["inventory_item_id"]
    if inventory_item_id.blank?
      logger.warn("#{self.class} skipped webhook #{webhook_id}: payload has no inventory_item_id")
      return
    end

    return if ProcessedWebhook.exists?(webhook_id: webhook_id)

    InventoryRefresher.call(shop: shop, inventory_item_id: inventory_item_id)
    ProcessedWebhook.claim(webhook_id: webhook_id, topic: TOPIC, shop_domain: shop_domain)
  end
end
