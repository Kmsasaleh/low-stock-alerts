# frozen_string_literal: true

class DashboardController < AuthenticatedController
  def forecast
    setting = current_shop.alert_setting
    rows = ShopForecast.call(shop: current_shop, setting: setting)

    render(json: {
      settings: settings_json(setting),
      urgent_count: rows.count { |row| row.forecast.label == :urgent },
      watch_count: rows.count { |row| row.forecast.label == :watch },
      retention_days: DataRetention::SALE_LINE_RETENTION.in_days.to_i,
      rows: rows.map { |row| row_json(row) },
    })
  end

  def update_settings
    setting = current_shop.alert_setting

    if setting.update(setting_params)
      render(json: { settings: settings_json(setting) })
    else
      render(json: { errors: setting.errors.full_messages }, status: 422)
    end
  end

  private

  def current_shop
    @current_shop ||= Shop.find_by!(shopify_domain: current_shopify_session.shop)
  end

  def setting_params
    params.require(:settings).permit(:urgent_days, :watch_days, :window_days, :alert_email)
  end

  def settings_json(setting)
    setting.slice(:urgent_days, :watch_days, :window_days, :alert_email)
  end

  def row_json(row)
    variant = row.variant
    {
      id: variant.id,
      product_title: variant.product_title,
      variant_title: variant.variant_title == "Default Title" ? nil : variant.variant_title,
      sku: variant.sku,
      inventory_quantity: variant.inventory_quantity,
      units_sold: row.units_sold,
      daily_rate: row.forecast.daily_rate,
      days_left: row.forecast.days_left,
      label: row.forecast.label,
      reason: row.forecast.reason,
    }
  end
end
