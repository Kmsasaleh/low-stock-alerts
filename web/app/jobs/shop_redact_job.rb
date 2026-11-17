# frozen_string_literal: true

class ShopRedactJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    Shop.find_by(shopify_domain: shop_domain)&.destroy!
    ProcessedWebhook.where(shop_domain: shop_domain).delete_all
    logger.info("#{self.class}: erased all stored data for '#{shop_domain}'")
  end
end
