class AddSubmittedToIssuesDraft < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_drafts, :submitted, :boolean, default: false, null: false
  end
end
