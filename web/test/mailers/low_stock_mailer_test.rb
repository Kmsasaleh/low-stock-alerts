# frozen_string_literal: true

require "test_helper"

class LowStockMailerTest < ActionMailer::TestCase
  test "lists the urgent products for the merchant" do
    shop = Shop.create!(shopify_domain: "mailer-test.myshopify.com", shopify_token: "test-token")
    shop.alert_setting.update!(alert_email: "merchant@example.com")
    low = shop.variants.create!(
      shopify_gid: "gid://shopify/ProductVariant/1",
      product_title: "Board",
      variant_title: "Ice",
      inventory_quantity: 2,
    )
    low.sale_lines.create!(shop: shop, shopify_line_item_id: "gid://shopify/LineItem/1", quantity: 14, sold_at: 1.day.ago)

    email = LowStockMailer.with(shop: shop, variant_ids: [low.id]).urgent

    assert_equal ["merchant@example.com"], email.to
    assert_equal "1 product is about to sell out", email.subject
    assert_match "Board – Ice: 2 in stock, 2.0 days left", email.text_part.body.to_s
  end
end
