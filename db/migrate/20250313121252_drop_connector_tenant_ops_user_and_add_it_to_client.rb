class DropConnectorTenantOpsUserAndAddItToClient < ActiveRecord::Migration[8.0]
  def change
    remove_column :connector_tenants, :ops_user_id, :integer
    add_column :clients, :triage_external_author_identifier, :integer
  end
end
