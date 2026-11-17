# frozen_string_literal: true

class UrgentAlerter
  def self.call(shop:, now: Time.current)
    new(shop: shop, now: now).call
  end

  def initialize(shop:, now:)
    @shop = shop
    @now = now
  end

  def call
    setting = @shop.alert_setting
    rows = ShopForecast.call(shop: @shop, setting: setting, now: @now)
    urgent_ids = rows.select { |row| row.forecast.label == :urgent }.map { |row| row.variant.id }

    @shop.variants.where.not(id: urgent_ids).where.not(urgent_alerted_at: nil).update_all(urgent_alerted_at: nil)
    return [] if setting.alert_email.blank?

    newly_urgent = urgent_ids.select { |id| claim(id) }
    LowStockMailer.with(shop: @shop, variant_ids: newly_urgent).urgent.deliver_later if newly_urgent.any?
    newly_urgent
  end

  private

  def claim(variant_id)
    @shop.variants.where(id: variant_id, urgent_alerted_at: nil).update_all(urgent_alerted_at: @now) == 1
  end
end
