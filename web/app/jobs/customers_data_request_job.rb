# frozen_string_literal: true

class CustomersDataRequestJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    logger.info("#{self.class}: no customer personal data is stored for '#{shop_domain}'; nothing to report")
  end
end
