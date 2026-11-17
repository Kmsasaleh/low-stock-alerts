# frozen_string_literal: true

class ShopForecast
  Row = Data.define(:variant, :units_sold, :forecast)

  class << self
    def call(shop:, setting: shop.alert_setting, now: Time.current)
      sold = SaleLine
        .where(shop: shop, sold_at: (now - setting.window_days.days)..now)
        .group(:variant_id)
        .sum(:quantity)

      rows = shop.variants.map do |variant|
        units_sold = sold.fetch(variant.id, 0)
        forecast = StockoutForecast.call(
          available: variant.inventory_quantity,
          units_sold: units_sold,
          window_days: setting.window_days,
          urgent_days: setting.urgent_days,
          watch_days: setting.watch_days,
        )
        Row.new(variant: variant, units_sold: units_sold, forecast: forecast)
      end

      rows.sort_by { |row| [row.forecast.days_left || Float::INFINITY, row.variant.product_title] }
    end
  end
end
