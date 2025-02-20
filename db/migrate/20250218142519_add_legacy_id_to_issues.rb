class AddLegacyIdToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :legacy_id, :integer
    add_index :issues, :legacy_id, unique: true
  end
end
