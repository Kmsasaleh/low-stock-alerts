class CreateVariants < ActiveRecord::Migration[7.1]
  def change
    create_table :variants do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :shopify_gid, null: false
      t.string :product_title, null: false
      t.string :variant_title
      t.string :sku
      t.integer :inventory_quantity, null: false, default: 0

      t.timestamps
    end

    add_index :variants, [:shop_id, :shopify_gid], unique: true
  end
end
