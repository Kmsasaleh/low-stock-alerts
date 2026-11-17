# frozen_string_literal: true

class Setting < ApplicationRecord
  MAX_WINDOW_DAYS = 60

  belongs_to :shop

  validates :urgent_days, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :watch_days, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :window_days,
    numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_WINDOW_DAYS }
  validates :alert_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validate :watch_not_below_urgent

  private

  def watch_not_below_urgent
    return if urgent_days.nil? || watch_days.nil?

    errors.add(:watch_days, "must be at least the urgent threshold") if watch_days < urgent_days
  end
end
