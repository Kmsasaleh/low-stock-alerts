# frozen_string_literal: true

module Webhooks
  class OrdersCreateController < ApplicationController
    include ShopifyApp::WebhookVerification

    def receive
      webhook_request = ShopifyAPI::Webhooks::Request.new(raw_body: request.raw_post, headers: request.headers.to_h)
      OrdersCreateJob.perform_later(
        shop_domain: webhook_request.shop,
        webhook_id: request.headers["X-Shopify-Webhook-Id"],
        webhook: webhook_request.parsed_body,
      )
      head(:no_content)
    end
  end
end
