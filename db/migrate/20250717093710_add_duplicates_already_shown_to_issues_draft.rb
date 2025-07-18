class AddDuplicatesAlreadyShownToIssuesDraft < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_drafts, :duplicates_shown, :boolean, default: false, null: false
  end
end
