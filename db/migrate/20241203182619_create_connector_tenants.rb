class CreateConnectorTenants < ActiveRecord::Migration[8.0]
  def change
    create_table :connector_tenants do |t|
      t.string :name
      t.string :api_token_private_key
      t.integer :api_subject_identifier
      t.string :webhook_public_key

      t.timestamps
    end
  end
end
