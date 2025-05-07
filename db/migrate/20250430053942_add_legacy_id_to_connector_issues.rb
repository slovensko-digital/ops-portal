class AddLegacyIdToConnectorIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :connector_issues, :legacy_id, :integer
  end
end
