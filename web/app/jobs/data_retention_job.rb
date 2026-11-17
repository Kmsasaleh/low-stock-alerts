# frozen_string_literal: true

class DataRetentionJob < ActiveJob::Base
  def perform
    deleted = DataRetention.call
    logger.info("#{self.class} deleted #{deleted[:sale_lines]} sale lines and #{deleted[:processed_webhooks]} processed webhooks")
  end
end
