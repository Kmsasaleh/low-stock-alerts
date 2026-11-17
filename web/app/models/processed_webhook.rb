# frozen_string_literal: true

class ProcessedWebhook < ApplicationRecord
  validates :webhook_id, :topic, :shop_domain, presence: true

  # Returns true if this delivery is new, false if we've already seen it.
  # INSERT ... ON CONFLICT DO NOTHING: the unique index makes this atomic,
  # so two workers racing on the same webhook can't both claim it.
  def self.claim(webhook_id:, topic:, shop_domain:)
    insert(
      { webhook_id: webhook_id, topic: topic, shop_domain: shop_domain },
      unique_by: :webhook_id,
    ).rows.any?
  end
end
