class CreateRodauthEmailAuth < ActiveRecord::Migration[8.1]
  def change
    create_table :user_email_auth_keys, id: false do |t|
      t.integer :id, primary_key: true
      t.foreign_key :users, column: :id
      t.string :key, null: false
      t.datetime :deadline, null: false
      t.datetime :email_last_sent, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end
