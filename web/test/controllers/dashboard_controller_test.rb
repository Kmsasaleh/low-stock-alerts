# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  SHOP_DOMAIN = "dashboard-test.myshopify.com"

  setup do
    @shop = Shop.create!(shopify_domain: SHOP_DOMAIN, shopify_token: "test-token")
    low = @shop.variants.create!(shopify_gid: "gid://shopify/ProductVariant/1", product_title: "Low", inventory_quantity: 2)
    @shop.variants.create!(shopify_gid: "gid://shopify/ProductVariant/2", product_title: "Plenty", inventory_quantity: 50)
    low.sale_lines.create!(shop: @shop, shopify_line_item_id: "gid://shopify/LineItem/1", quantity: 14, sold_at: 1.day.ago)
  end

  test "rejects a request with an invalid session token" do
    get "/api/forecast", headers: { "Authorization" => "Bearer not-a-real-token" }

    assert_response :unauthorized
  end

  test "returns the shop's forecast sorted soonest first" do
    sign_in

    get "/api/forecast"

    assert_response :ok
    body = response.parsed_body
    assert_equal ["Low", "Plenty"], body["rows"].map { |row| row["product_title"] }
    assert_equal "urgent", body["rows"].first["label"]
    assert_equal 1, body["urgent_count"]
    assert_equal 14, body["settings"]["window_days"]
  end

  test "never returns another shop's products" do
    other = Shop.create!(shopify_domain: "someone-else.myshopify.com", shopify_token: "other-token")
    other.variants.create!(shopify_gid: "gid://shopify/ProductVariant/9", product_title: "Not yours", inventory_quantity: 1)
    sign_in

    get "/api/forecast"

    assert_not_includes response.parsed_body["rows"].map { |row| row["product_title"] }, "Not yours"
  end

  test "saves valid settings" do
    sign_in

    patch "/api/settings",
      params: { settings: { urgent_days: 2, watch_days: 10, window_days: 30, alert_email: "merchant@example.com" } },
      as: :json

    assert_response :ok
    setting = Setting.find_by!(shop: @shop)
    assert_equal [2, 10, 30], [setting.urgent_days, setting.watch_days, setting.window_days]
  end

  test "rejects invalid settings with messages and changes nothing" do
    sign_in

    patch "/api/settings", params: { settings: { window_days: 90 } }, as: :json

    assert_response 422
    assert_match(/Window days/, response.parsed_body["errors"].join)
    assert_equal 14, Setting.find_by!(shop: @shop).window_days
  end

  private

  def sign_in
    DashboardController.any_instance.stubs(:activate_shopify_session).yields
    DashboardController.any_instance.stubs(:current_shopify_session)
      .returns(ShopifyAPI::Auth::Session.new(shop: SHOP_DOMAIN))
  end
end
