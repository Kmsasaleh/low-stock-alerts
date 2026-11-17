# frozen_string_literal: true

class AddUrgentAlertedAtToVariants < ActiveRecord::Migration[7.1]
  def change
    add_column :variants, :urgent_alerted_at, :datetime
  end
end
