# frozen_string_literal: true

require "test_helper"

module Webhooks
  class OrdersCreateControllerTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    TEST_SECRET = "test-webhook-secret"
    BODY = { id: 5001, created_at: "2026-11-16T10:00:00-05:00", line_items: [] }.to_json

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
      assert_enqueued_with(job: OrdersCreateJob) do
        post_webhook(hmac: sign(BODY))
      end

      assert_response :no_content
    end

    private

    def post_webhook(hmac:)
      post "/api/webhooks/orders_create",
        params: BODY,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "X-Shopify-Topic" => "orders/create",
          "X-Shopify-Shop-Domain" => "webhook-test.myshopify.com",
          "X-Shopify-Webhook-Id" => "wh-controller-1",
          "X-Shopify-API-Version" => "2027-01",
          "X-Shopify-Hmac-Sha256" => hmac,
        }
    end

    def sign(body)
      Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", TEST_SECRET, body))
    end
  end
end
