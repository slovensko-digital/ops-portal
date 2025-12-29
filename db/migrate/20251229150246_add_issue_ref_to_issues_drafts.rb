class AddIssueRefToIssuesDrafts < ActiveRecord::Migration[8.1]
  def change
    add_reference :issues_drafts, :issue, foreign_key: true, index: { unique: true }
  end
end
