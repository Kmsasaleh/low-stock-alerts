class CreateProcessedWebhooks < ActiveRecord::Migration[7.1]
  def change
    create_table :processed_webhooks do |t|
      t.string :webhook_id, null: false
      t.string :topic, null: false
      t.string :shop_domain, null: false

      t.timestamps
    end

    add_index :processed_webhooks, :webhook_id, unique: true
  end
end
