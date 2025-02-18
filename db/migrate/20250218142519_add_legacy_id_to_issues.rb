class AddLegacyIdToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :legacy_id, :integer
  end
end
