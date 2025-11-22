class AddResolvesIssueToIssuesUpdates < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_updates, :resolves_issue, :boolean, default: false, null: false
  end
end
