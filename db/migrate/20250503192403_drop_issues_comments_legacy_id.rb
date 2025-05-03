class DropIssuesCommentsLegacyId < ActiveRecord::Migration[8.0]
  def change
    remove_column :issues_comments, :legacy_id, :integer
  end
end
