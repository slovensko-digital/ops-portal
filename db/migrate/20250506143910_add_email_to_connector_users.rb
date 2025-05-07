class AddEmailToConnectorUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :connector_users, :email, :string
  end
end
