# frozen_string_literal: true

require "test_helper"

module Webhooks
  class InventoryLevelsUpdateControllerTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    TEST_SECRET = "test-webhook-secret"
    BODY = { inventory_item_id: 555, location_id: 1, available: 46 }.to_json

    setup do
      ShopifyApp.configuration.stubs(:secret).returns(TEST_SECRET)
      ShopifyApp.configuration.stubs(:old_secret).returns(nil)
    end

    test "rejects a request with a bad signature and enqueues nothing" do
      assert_no_enqueued_jobs do
        post_webhook(hmac: "not-a-real-signature")
      end

      assert_response :unauthorized
    end

    test "accepts a correctly signed request and enqueues the job" do
      assert_enqueued_with(job: InventoryLevelsUpdateJob) do
        post_webhook(hmac: Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", TEST_SECRET, BODY)))
      end

      assert_response :no_content
    end

    private

    def post_webhook(hmac:)
      post "/api/webhooks/inventory_levels_update",
        params: BODY,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "X-Shopify-Topic" => "inventory_levels/update",
          "X-Shopify-Shop-Domain" => "inventory-job-test.myshopify.com",
          "X-Shopify-Webhook-Id" => "inv-controller-1",
          "X-Shopify-API-Version" => "2027-01",
          "X-Shopify-Hmac-Sha256" => hmac,
        }
    end
  end
end
