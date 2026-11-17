# frozen_string_literal: true

class AddUserExpiresAtColumn < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :expires_at, :datetime
  end
end
