class AddLegacyIdToConnectorActivities < ActiveRecord::Migration[8.0]
  def change
    add_column :connector_activities, :legacy_id, :integer
  end
end
