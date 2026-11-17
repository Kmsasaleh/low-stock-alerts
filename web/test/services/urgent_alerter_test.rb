# frozen_string_literal: true

require "test_helper"

class UrgentAlerterTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @shop = Shop.create!(shopify_domain: "alerter-test.myshopify.com", shopify_token: "test-token")
    @shop.alert_setting.update!(alert_email: "merchant@example.com")
    @low = @shop.variants.create!(shopify_gid: "gid://shopify/ProductVariant/1", product_title: "Low", inventory_quantity: 2)
    @shop.variants.create!(shopify_gid: "gid://shopify/ProductVariant/2", product_title: "Plenty", inventory_quantity: 50)
    @low.sale_lines.create!(shop: @shop, shopify_line_item_id: "gid://shopify/LineItem/1", quantity: 14, sold_at: 1.day.ago)
  end

  test "emails a newly urgent product once, not on every check" do
    assert_enqueued_emails(1) { assert_equal [@low.id], UrgentAlerter.call(shop: @shop) }
    assert_no_enqueued_emails { assert_equal [], UrgentAlerter.call(shop: @shop) }
  end

  test "sends nothing and claims nothing when no alert email is set" do
    @shop.alert_setting.update!(alert_email: nil)

    assert_no_enqueued_emails { UrgentAlerter.call(shop: @shop) }
    assert_nil @low.reload.urgent_alerted_at
  end

  test "a product that recovers and becomes urgent again alerts again" do
    UrgentAlerter.call(shop: @shop)
    @low.update!(inventory_quantity: 500)
    UrgentAlerter.call(shop: @shop)
    assert_nil @low.reload.urgent_alerted_at

    @low.update!(inventory_quantity: 2)

    assert_enqueued_emails(1) { UrgentAlerter.call(shop: @shop) }
  end
end
