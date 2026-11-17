# frozen_string_literal: true

require "test_helper"

class ShopForecastTest < ActiveSupport::TestCase
  setup do
    @now = Time.zone.parse("2026-11-16 12:00")
    @shop = Shop.create!(shopify_domain: "forecast-test.myshopify.com", shopify_token: "token")
    @fast = @shop.variants.create!(shopify_gid: "gid://test/1", product_title: "Fast", inventory_quantity: 4)
    @slow = @shop.variants.create!(shopify_gid: "gid://test/2", product_title: "Slow", inventory_quantity: 50)
    @idle = @shop.variants.create!(shopify_gid: "gid://test/3", product_title: "Idle", inventory_quantity: 9)
  end

  test "only counts sales inside the window and sorts soonest first" do
    sell(@fast, "li-1", 14, @now - 2.days)
    sell(@slow, "li-2", 7, @now - 3.days)
    sell(@fast, "li-old", 100, @now - 30.days)

    rows = ShopForecast.call(shop: @shop, now: @now)

    assert_equal ["Fast", "Slow", "Idle"], rows.map { |row| row.variant.product_title }
    assert_equal 14, rows.first.units_sold
    assert_equal :watch, rows.first.forecast.label
    assert_nil rows.last.forecast.days_left
  end

  test "uses the shop's own thresholds" do
    @shop.alert_setting.update!(urgent_days: 5)
    sell(@fast, "li-1", 14, @now - 2.days)

    rows = ShopForecast.call(shop: @shop, now: @now)

    assert_equal :urgent, rows.first.forecast.label
  end

  private

  def sell(variant, line_item_id, quantity, sold_at)
    variant.sale_lines.create!(shop: @shop, shopify_line_item_id: line_item_id, quantity: quantity, sold_at: sold_at)
  end
end
