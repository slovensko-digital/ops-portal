class AddLegacyIdToIssuesUpdates < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_updates, :legacy_id, :integer
    add_index :issues_updates, :legacy_id, unique: true
  end
end
