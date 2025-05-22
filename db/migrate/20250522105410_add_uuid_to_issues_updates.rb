class AddUuidToIssuesUpdates < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_updates, :uuid, :uuid
    add_index :issues_updates, :uuid, unique: true
  end
end
