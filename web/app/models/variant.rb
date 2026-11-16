# frozen_string_literal: true

class Variant < ApplicationRecord
  belongs_to :shop
  has_many :sale_lines, dependent: :destroy

  validates :shopify_gid, presence: true, uniqueness: { scope: :shop_id }
  validates :product_title, presence: true
  validates :inventory_quantity, numericality: { only_integer: true }
end
