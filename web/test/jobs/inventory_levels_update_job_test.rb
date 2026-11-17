# frozen_string_literal: true

require "test_helper"

class InventoryLevelsUpdateJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  SHOP_DOMAIN = "inventory-job-test.myshopify.com"

  setup do
    Shop.create!(shopify_domain: SHOP_DOMAIN, shopify_token: "test-token")
  end

  test "the same delivery twice calls Shopify once" do
    InventoryRefresher.expects(:call).once.returns(1)

    2.times { deliver("inv-1", { "inventory_item_id" => 555 }) }

    assert_equal 1, ProcessedWebhook.count
  end

  test "an empty payload is skipped without calling Shopify" do
    InventoryRefresher.expects(:call).never

    deliver("inv-2", {})

    assert_equal 0, ProcessedWebhook.count
  end

  test "a Shopify failure schedules a retry and records nothing" do
    InventoryRefresher.stubs(:call).raises(InventoryRefresher::Error, "Throttled")

    assert_enqueued_with(job: InventoryLevelsUpdateJob) do
      deliver("inv-3", { "inventory_item_id" => 555 })
    end

    assert_equal 0, ProcessedWebhook.count
  end

  private

  def deliver(webhook_id, payload)
    InventoryLevelsUpdateJob.perform_now(shop_domain: SHOP_DOMAIN, webhook_id: webhook_id, webhook: payload)
  end
end
