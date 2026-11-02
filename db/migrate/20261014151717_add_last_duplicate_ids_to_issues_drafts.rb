class AddLastDuplicateIdsToIssuesDrafts < ActiveRecord::Migration[8.1]
  def change
    add_column :issues_drafts, :last_duplicate_ids, :bigint, array: true
  end
end
