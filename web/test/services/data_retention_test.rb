# frozen_string_literal: true

require "test_helper"

class DataRetentionTest < ActiveSupport::TestCase
  setup do
    @now = Time.zone.parse("2026-11-16 12:00")
    @shop = Shop.create!(shopify_domain: "retention-test.myshopify.com", shopify_token: "test-token")
    @variant = @shop.variants.create!(shopify_gid: "gid://shopify/ProductVariant/1", product_title: "Board", inventory_quantity: 5)
  end

  test "deletes sales older than 90 days and keeps newer ones" do
    sell("old", @now - 91.days)
    sell("recent", @now - 89.days)

    result = DataRetention.call(now: @now)

    assert_equal 1, result[:sale_lines]
    assert_equal ["recent"], SaleLine.pluck(:shopify_line_item_id)
  end

  test "deletes processed webhook records older than 7 days and keeps newer ones" do
    ProcessedWebhook.create!(webhook_id: "old", topic: "orders/create", shop_domain: @shop.shopify_domain, created_at: @now - 8.days)
    ProcessedWebhook.create!(webhook_id: "recent", topic: "orders/create", shop_domain: @shop.shopify_domain, created_at: @now - 6.days)

    result = DataRetention.call(now: @now)

    assert_equal 1, result[:processed_webhooks]
    assert_equal ["recent"], ProcessedWebhook.pluck(:webhook_id)
  end

  private

  def sell(line_item_id, sold_at)
    @variant.sale_lines.create!(shop: @shop, shopify_line_item_id: line_item_id, quantity: 1, sold_at: sold_at)
  end
end
