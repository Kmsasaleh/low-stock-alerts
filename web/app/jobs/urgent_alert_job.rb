# frozen_string_literal: true

class UrgentAlertJob < ActiveJob::Base
  def perform(shop_id)
    shop = Shop.find_by(id: shop_id)
    return if shop.nil?

    UrgentAlerter.call(shop: shop)
  end
end
