# frozen_string_literal: true

class StockoutForecast
  Result = Data.define(:daily_rate, :days_left, :label, :reason)

  DEFAULT_WINDOW_DAYS = 14
  DEFAULT_URGENT_DAYS = 3
  DEFAULT_WATCH_DAYS = 7

  def self.call(available:, units_sold:, window_days: DEFAULT_WINDOW_DAYS,
    urgent_days: DEFAULT_URGENT_DAYS, watch_days: DEFAULT_WATCH_DAYS)
    new(
      available: available,
      units_sold: units_sold,
      window_days: window_days,
      urgent_days: urgent_days,
      watch_days: watch_days,
    ).call
  end

  def initialize(available:, units_sold:, window_days:, urgent_days:, watch_days:)
    raise ArgumentError, "window_days must be positive" unless window_days.positive?
    raise ArgumentError, "urgent_days must not exceed watch_days" if urgent_days > watch_days

    @available = available
    @units_sold = units_sold
    @window_days = window_days
    @urgent_days = urgent_days
    @watch_days = watch_days
  end

  def call
    return out_of_stock if @available <= 0
    return no_recent_sales if @units_sold <= 0

    days_left = (@available / daily_rate).round(1)
    Result.new(daily_rate: daily_rate.round(2), days_left: days_left, label: label_for(days_left), reason: :forecast)
  end

  private

  def daily_rate
    @units_sold.to_f / @window_days
  end

  def label_for(days_left)
    if days_left <= @urgent_days then :urgent
    elsif days_left <= @watch_days then :watch
    else :ok
    end
  end

  def out_of_stock
    Result.new(daily_rate: daily_rate.round(2), days_left: 0.0, label: :urgent, reason: :out_of_stock)
  end

  def no_recent_sales
    Result.new(daily_rate: 0.0, days_left: nil, label: :ok, reason: :no_recent_sales)
  end
end
