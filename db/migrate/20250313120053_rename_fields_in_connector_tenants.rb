class RenameFieldsInConnectorTenants < ActiveRecord::Migration[8.0]
  def change
    rename_column :connector_tenants, :api_subject_identifier, :ops_api_subject_identifier
    rename_column :connector_tenants, :api_token_private_key, :ops_api_token_private_key
    rename_column :connector_tenants, :webhook_public_key, :ops_webhook_public_key
    rename_column :connector_tenants, :triage_user_id, :ops_user_id
    rename_column :connector_tenants, :url, :backoffice_url
    rename_column :connector_tenants, :api_token, :backoffice_api_token
    rename_column :connector_tenants, :webhook_secret, :backoffice_webhook_secret
  end
end
