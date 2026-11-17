# frozen_string_literal: true

class Shop < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorage
  has_many :variants, dependent: :destroy
  has_one :setting, dependent: :destroy

  def api_version
    ShopifyApp.configuration.api_version
  end

  def alert_setting
    @alert_setting ||= setting || Setting.create_or_find_by!(shop: self)
  end
end
