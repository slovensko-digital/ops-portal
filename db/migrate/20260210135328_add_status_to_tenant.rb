class AddStatusToTenant < ActiveRecord::Migration[8.1]
  def change
    add_column :connector_tenants, :status, :integer, null: false, default: 0
  end
end
