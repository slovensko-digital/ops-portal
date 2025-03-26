class RenameConnectorUsersZammadIdentifierToExternalId < ActiveRecord::Migration[8.0]
  def change
    rename_column :connector_users, :zammad_identifier, :external_id
  end
end
