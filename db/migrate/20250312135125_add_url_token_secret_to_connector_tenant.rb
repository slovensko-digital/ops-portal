class AddUrlTokenSecretToConnectorTenant < ActiveRecord::Migration[8.0]
  def change
    add_column :connector_tenants, :url, :string
    add_column :connector_tenants, :api_token, :string
    add_column :connector_tenants, :webhook_secret, :string
  end
end
