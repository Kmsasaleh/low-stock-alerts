class Variant < ApplicationRecord
  belongs_to :shop

  validates :shopify_gid, presence: true, uniqueness: { scope: :shop_id }
  validates :product_title, presence: true
  validates :inventory_quantity, numericality: { only_integer: true }
end