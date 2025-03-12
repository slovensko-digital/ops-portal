class RemoveConnectorBackofficeInstance < ActiveRecord::Migration[8.0]
  def change
    remove_reference :connector_users, :connector_backoffice_instance, foreign_key: true
    remove_reference :connector_comments, :connector_backoffice_instance, foreign_key: true
    remove_reference :connector_issues, :connector_backoffice_instance, foreign_key: true
    remove_reference :connector_tenants, :connector_backoffice_instance, foreign_key: true

    drop_table :connector_backoffice_instances
  end
end
