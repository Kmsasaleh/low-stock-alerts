# frozen_string_literal: true

require "test_helper"

class SettingTest < ActiveSupport::TestCase
  setup do
    @shop = Shop.create!(shopify_domain: "settings-test.myshopify.com", shopify_token: "test-token")
  end

  test "a new shop gets default thresholds" do
    setting = @shop.alert_setting

    assert setting.persisted?
    assert_equal [3, 7, 14], [setting.urgent_days, setting.watch_days, setting.window_days]
    assert_nil setting.alert_email
  end

  test "asking again returns the same row instead of creating another" do
    first = @shop.alert_setting
    again = Shop.find(@shop.id).alert_setting

    assert_equal first.id, again.id
    assert_equal 1, Setting.where(shop: @shop).count
  end

  test "the sales window must fit inside the 60 days read_orders allows" do
    setting = @shop.alert_setting

    setting.window_days = 61
    assert_not setting.valid?

    setting.window_days = 0
    assert_not setting.valid?

    setting.window_days = 60
    assert setting.valid?
  end

  test "watch threshold cannot be below the urgent threshold" do
    setting = @shop.alert_setting
    setting.assign_attributes(urgent_days: 5, watch_days: 3)

    assert_not setting.valid?
    assert_includes setting.errors[:watch_days], "must be at least the urgent threshold"
  end

  test "alert email must look like an email but may be blank" do
    setting = @shop.alert_setting

    setting.alert_email = "not-an-email"
    assert_not setting.valid?

    setting.alert_email = "merchant@example.com"
    assert setting.valid?

    setting.alert_email = ""
    assert setting.valid?
  end

  test "settings are deleted with the shop" do
    @shop.alert_setting
    @shop.destroy!

    assert_equal 0, Setting.where(shop_id: @shop.id).count
  end
end
