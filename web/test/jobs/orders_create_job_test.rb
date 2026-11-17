# frozen_string_literal: true

require "test_helper"

class OrdersCreateJobTest < ActiveSupport::TestCase
  SHOP_DOMAIN = "webhook-test.myshopify.com"

  setup do
    @shop = Shop.create!(shopify_domain: SHOP_DOMAIN, shopify_token: "test-token")
    @variant = @shop.variants.create!(
      shopify_gid: "gid://shopify/ProductVariant/111",
      product_title: "Board",
      inventory_quantity: 10,
    )
  end

  test "the same delivery twice is counted once" do
    2.times { deliver("wh-1", [line_item(id: 9001, variant_id: 111, quantity: 3)]) }

    assert_equal 1, SaleLine.count
    assert_equal 3, @variant.sale_lines.sum(:quantity)
    assert_equal 1, ProcessedWebhook.count
  end

  test "a line item already stored by OrdersImporter is not double counted" do
    @variant.sale_lines.create!(
      shop: @shop,
      shopify_line_item_id: "gid://shopify/LineItem/9001",
      quantity: 3,
      sold_at: 1.hour.ago,
    )

    deliver("wh-2", [line_item(id: 9001, variant_id: 111, quantity: 3)])

    assert_equal 1, SaleLine.count
  end

  test "skips custom items and variants we don't track" do
    deliver("wh-3", [
      line_item(id: 1, variant_id: nil, quantity: 1),
      line_item(id: 2, variant_id: 999, quantity: 1),
      line_item(id: 3, variant_id: 111, quantity: 2),
    ])

    assert_equal ["gid://shopify/LineItem/3"], SaleLine.pluck(:shopify_line_item_id)
  end

  test "a failure releases the claim so Shopify's retry is processed" do
    SaleLine.stubs(:upsert_all).raises(ActiveRecord::StatementInvalid, "simulated DB failure")
    assert_raises(ActiveRecord::StatementInvalid) do
      deliver("wh-4", [line_item(id: 9001, variant_id: 111, quantity: 3)])
    end
    assert_equal 0, ProcessedWebhook.count, "claim should roll back with the failed write"

    SaleLine.unstub(:upsert_all)
    deliver("wh-4", [line_item(id: 9001, variant_id: 111, quantity: 3)])

    assert_equal 1, SaleLine.count
  end

  private

  def deliver(webhook_id, line_items)
    OrdersCreateJob.perform_now(
      shop_domain: SHOP_DOMAIN,
      webhook_id: webhook_id,
      webhook: { "id" => 5001, "created_at" => "2026-11-16T10:00:00-05:00", "line_items" => line_items },
    )
  end

  def line_item(id:, variant_id:, quantity:)
    { "id" => id, "variant_id" => variant_id, "quantity" => quantity }
  end
end
