# frozen_string_literal: true

require "test_helper"

class StockoutForecastTest < ActiveSupport::TestCase
  test "steady sales give days left and the right label" do
    result = StockoutForecast.call(available: 10, units_sold: 14, window_days: 14)

    assert_in_delta 1.0, result.daily_rate
    assert_in_delta 10.0, result.days_left
    assert_equal :ok, result.label
    assert_equal :forecast, result.reason
  end

  test "labels watch within the watch threshold" do
    assert_equal :watch, StockoutForecast.call(available: 5, units_sold: 14).label
  end

  test "labels urgent within the urgent threshold" do
    assert_equal :urgent, StockoutForecast.call(available: 2, units_sold: 14).label
  end

  test "thresholds are inclusive" do
    assert_equal :watch, StockoutForecast.call(available: 7, units_sold: 14).label
    assert_equal :urgent, StockoutForecast.call(available: 3, units_sold: 14).label
  end

  test "zero stock is urgent even with no sales" do
    result = StockoutForecast.call(available: 0, units_sold: 0)

    assert_equal :urgent, result.label
    assert_equal :out_of_stock, result.reason
    assert_in_delta 0.0, result.days_left
  end

  test "oversold (negative) stock is urgent" do
    assert_equal :out_of_stock, StockoutForecast.call(available: -2, units_sold: 5).reason
  end

  test "no recent sales means no stockout date" do
    result = StockoutForecast.call(available: 10, units_sold: 0)

    assert_nil result.days_left
    assert_equal :ok, result.label
    assert_equal :no_recent_sales, result.reason
  end

  test "rounds slow sellers sensibly" do
    result = StockoutForecast.call(available: 10, units_sold: 3, window_days: 14)

    assert_in_delta 0.21, result.daily_rate
    assert_in_delta 46.7, result.days_left
  end

  test "rejects a non-positive window" do
    assert_raises(ArgumentError) { StockoutForecast.call(available: 1, units_sold: 1, window_days: 0) }
  end
end
