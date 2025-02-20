class AddLegacyIdToIssuesCategories < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_categories, :legacy_id, :integer
    add_index :issues_categories, :legacy_id, unique: true
  end
end
