class AddIssueTypeToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :issue_type, :integer, default: 1
  end
end
