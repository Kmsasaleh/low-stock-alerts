# frozen_string_literal: true

class LowStockMailer < ApplicationMailer
  def urgent
    @shop = params[:shop]
    @setting = @shop.alert_setting
    @rows = ShopForecast.call(shop: @shop, setting: @setting)
      .select { |row| params[:variant_ids].include?(row.variant.id) }

    count = @rows.size
    subject = count == 1 ? "1 product is about to sell out" : "#{count} products are about to sell out"
    mail(to: @setting.alert_email, subject: subject)
  end
end
