class CreateSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :settings do |t|
      t.references :shop, null: false, foreign_key: true, index: { unique: true }
      t.integer :urgent_days, null: false, default: 3
      t.integer :watch_days, null: false, default: 7
      t.integer :window_days, null: false, default: 14
      t.string :alert_email

      t.timestamps
    end
  end
end
