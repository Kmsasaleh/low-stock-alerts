# frozen_string_literal: true

class SaleLine < ApplicationRecord
  belongs_to :shop
  belongs_to :variant

  validates :shopify_line_item_id, presence: true, uniqueness: { scope: :shop_id }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :sold_at, presence: true
end
