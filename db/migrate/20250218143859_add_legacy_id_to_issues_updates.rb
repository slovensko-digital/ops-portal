class AddLegacyIdToIssuesUpdates < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_updates, :legacy_id, :integer
  end
end
