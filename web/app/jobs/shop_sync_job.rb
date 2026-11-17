# frozen_string_literal: true

class ShopSyncJob < ActiveJob::Base
  retry_on ShopifyAPI::Errors::HttpResponseError, wait: :polynomially_longer, attempts: 5

  def perform(shop_id)
    shop = Shop.find_by(id: shop_id)
    if shop.nil?
      logger.info("#{self.class} skipped: shop #{shop_id} no longer exists")
      return
    end

    shop.with_shopify_session do |session|
      variants = VariantSync.call(shop: shop, session: session)
      sale_lines = OrdersImporter.call(shop: shop, session: session)
      logger.info("#{self.class} synced '#{shop.shopify_domain}': #{variants} variants, #{sale_lines} sale lines")
    end
  end
end
