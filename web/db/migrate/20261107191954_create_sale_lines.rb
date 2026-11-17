# frozen_string_literal: true

class CreateSaleLines < ActiveRecord::Migration[7.1]
  def change
    create_table :sale_lines do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :variant, null: false, foreign_key: true
      t.string :shopify_line_item_id, null: false
      t.integer :quantity, null: false
      t.datetime :sold_at, null: false

      t.timestamps
    end

    add_index :sale_lines, [:shop_id, :shopify_line_item_id], unique: true
    add_index :sale_lines, [:variant_id, :sold_at]
  end
end
