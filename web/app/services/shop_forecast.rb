# frozen_string_literal: true

class ShopForecast
  Row = Data.define(:variant, :units_sold, :forecast)

  def self.call(shop:, window_days: StockoutForecast::DEFAULT_WINDOW_DAYS, now: Time.current)
    sold = SaleLine
      .where(shop: shop, sold_at: (now - window_days.days)..now)
      .group(:variant_id)
      .sum(:quantity)

    rows = shop.variants.map do |variant|
      units_sold = sold.fetch(variant.id, 0)
      forecast = StockoutForecast.call(
        available: variant.inventory_quantity,
        units_sold: units_sold,
        window_days: window_days,
      )
      Row.new(variant: variant, units_sold: units_sold, forecast: forecast)
    end

    rows.sort_by { |row| row.forecast.days_left || Float::INFINITY }
  end
end
