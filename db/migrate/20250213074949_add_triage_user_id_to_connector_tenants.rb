class AddTriageUserIdToConnectorTenants < ActiveRecord::Migration[8.0]
  def change
    add_column :connector_tenants, :triage_user_id, :integer
  end
end
