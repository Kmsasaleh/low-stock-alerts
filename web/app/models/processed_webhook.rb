# frozen_string_literal: true

class ProcessedWebhook < ApplicationRecord
  validates :webhook_id, :topic, :shop_domain, presence: true

  class << self
    def claim(webhook_id:, topic:, shop_domain:)
      insert(
        { webhook_id: webhook_id, topic: topic, shop_domain: shop_domain },
        unique_by: :webhook_id,
      ).rows.any?
    end
  end
end
