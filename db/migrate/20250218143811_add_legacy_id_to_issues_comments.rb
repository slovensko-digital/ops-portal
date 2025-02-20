class AddLegacyIdToIssuesComments < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_comments, :legacy_id, :integer
    add_index :issues_comments, :legacy_id, unique: true
  end
end
