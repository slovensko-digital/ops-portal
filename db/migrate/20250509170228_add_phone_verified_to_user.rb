class AddPhoneVerifiedToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :phone_verified, :boolean, null: false, default: false
    add_column :users, :phone_verification_attempts, :integer, null: false, default: 0
    add_column :users, :phone_verification_code, :string
    add_column :users, :phone_verification_code_attempts, :integer, null: false, default: 0
    add_column :users, :phone_verification_attempted_at, :datetime
  end
end
