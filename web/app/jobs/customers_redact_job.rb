# frozen_string_literal: true

class CustomersRedactJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    logger.info("#{self.class}: no customer personal data is stored for '#{shop_domain}'; nothing to redact")
  end
end
