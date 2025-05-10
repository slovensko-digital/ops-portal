class AddIssueTypeToIssuesDrafts < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_drafts, :issue_type, :string, default: 'issue', null: false
  end
end
