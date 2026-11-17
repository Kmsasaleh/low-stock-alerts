# frozen_string_literal: true

require "test_helper"

class ShopRedactJobTest < ActiveSupport::TestCase
  SHOP_DOMAIN = "redact-test.myshopify.com"

  test "erases the shop and everything stored for it" do
    shop = Shop.create!(shopify_domain: SHOP_DOMAIN, shopify_token: "test-token")
    variant = shop.variants.create!(shopify_gid: "gid://shopify/ProductVariant/1", product_title: "Board", inventory_quantity: 5)
    variant.sale_lines.create!(shop: shop, shopify_line_item_id: "gid://shopify/LineItem/1", quantity: 1, sold_at: 1.day.ago)
    ProcessedWebhook.claim(webhook_id: "wh-redact", topic: "orders/create", shop_domain: SHOP_DOMAIN)

    ShopRedactJob.perform_now(shop_domain: SHOP_DOMAIN, webhook: {})

    assert_nil Shop.find_by(shopify_domain: SHOP_DOMAIN)
    assert_equal 0, Variant.where(shop_id: shop.id).count
    assert_equal 0, SaleLine.where(shop_id: shop.id).count
    assert_equal 0, ProcessedWebhook.where(shop_domain: SHOP_DOMAIN).count
  end

  test "succeeds when the shop was already removed by app/uninstalled" do
    assert_nothing_raised do
      ShopRedactJob.perform_now(shop_domain: SHOP_DOMAIN, webhook: {})
    end
  end
end
