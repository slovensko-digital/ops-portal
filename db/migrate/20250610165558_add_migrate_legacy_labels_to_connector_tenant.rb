class AddMigrateLegacyLabelsToConnectorTenant < ActiveRecord::Migration[8.0]
  def change
    add_column :connector_tenants, :migrate_legacy_labels, :boolean, default: true
  end
end
