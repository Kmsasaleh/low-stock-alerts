# frozen_string_literal: true

require "test_helper"

class ShopSyncJobTest < ActiveSupport::TestCase
  setup do
    @shop = Shop.create!(shopify_domain: "sync-test.myshopify.com", shopify_token: "test-token")
  end

  test "syncs variants then sales using the shop's auto-refreshing session" do
    session = stub("session")
    Shop.any_instance.expects(:with_shopify_session).yields(session)
    sync = sequence("sync")
    VariantSync.expects(:call).with(shop: @shop, session: session).returns(21).in_sequence(sync)
    OrdersImporter.expects(:call).with(shop: @shop, session: session).returns(4).in_sequence(sync)

    ShopSyncJob.perform_now(@shop.id)
  end

  test "skips quietly when the shop was uninstalled before the job ran" do
    VariantSync.expects(:call).never
    OrdersImporter.expects(:call).never

    ShopSyncJob.perform_now(@shop.id + 1000)
  end
end
