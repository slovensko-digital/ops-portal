class AddReceiveCustomerActivitiesToConnectorTenants < ActiveRecord::Migration[8.0]
  def change
    add_column :connector_tenants, :receive_customer_activities, :boolean, default: false, null: false
  end
end
