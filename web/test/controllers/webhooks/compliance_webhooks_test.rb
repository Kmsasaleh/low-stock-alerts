# frozen_string_literal: true

require "test_helper"

module Webhooks
  class ComplianceWebhooksTest < ActionDispatch::IntegrationTest
    include ActiveJob::TestHelper

    TEST_SECRET = "test-webhook-secret"
    SHOP_DOMAIN = "compliance-test.myshopify.com"

    setup do
      ShopifyApp.configuration.stubs(:secret).returns(TEST_SECRET)
      ShopifyApp.configuration.stubs(:old_secret).returns(nil)
    end

    test "customers/data_request is accepted and enqueues its job" do
      assert_enqueued_with(job: CustomersDataRequestJob) do
        post_signed("/api/webhooks/customers_data_request", "customers/data_request")
      end
      assert_response :no_content
    end

    test "customers/redact is accepted and enqueues its job" do
      assert_enqueued_with(job: CustomersRedactJob) do
        post_signed("/api/webhooks/customers_redact", "customers/redact")
      end
      assert_response :no_content
    end

    test "shop/redact is accepted and enqueues its job" do
      assert_enqueued_with(job: ShopRedactJob) do
        post_signed("/api/webhooks/shop_redact", "shop/redact")
      end
      assert_response :no_content
    end

    test "compliance webhooks reject a bad signature" do
      assert_no_enqueued_jobs do
        post_signed("/api/webhooks/shop_redact", "shop/redact", hmac: "not-a-real-signature")
      end
      assert_response :unauthorized
    end

    private

    def post_signed(path, topic, hmac: nil)
      body = { shop_domain: SHOP_DOMAIN }.to_json
      post path,
        params: body,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "X-Shopify-Topic" => topic,
          "X-Shopify-Shop-Domain" => SHOP_DOMAIN,
          "X-Shopify-Webhook-Id" => "compliance-#{topic}",
          "X-Shopify-API-Version" => "2027-01",
          "X-Shopify-Hmac-Sha256" => hmac || Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", TEST_SECRET, body)),
        }
    end
  end
end
