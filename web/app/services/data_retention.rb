# frozen_string_literal: true

class DataRetention
  SALE_LINE_RETENTION = 90.days
  PROCESSED_WEBHOOK_RETENTION = 7.days

  class << self
    def call(now: Time.current)
      {
        sale_lines: SaleLine.where(sold_at: ...(now - SALE_LINE_RETENTION)).in_batches(of: 1000).delete_all,
        processed_webhooks: ProcessedWebhook.where(created_at: ...(now - PROCESSED_WEBHOOK_RETENTION)).in_batches(of: 1000).delete_all,
      }
    end
  end
end
