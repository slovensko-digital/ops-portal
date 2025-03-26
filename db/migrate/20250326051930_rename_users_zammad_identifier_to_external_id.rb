class RenameUsersZammadIdentifierToExternalId < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :zammad_identifier, :external_id
  end
end
