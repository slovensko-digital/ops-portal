class RemoveVerifiedAndVerificationFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :verified, :boolean, default: false, null: false
    remove_column :users, :verification, :string
  end
end
