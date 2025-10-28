class AddDisplayDateIndexToIssues < ActiveRecord::Migration[8.0]
  def change
    add_index :issues, "COALESCE(resolution_started_at, created_at) DESC", name: "index_issues_on_effective_date"
  end
end
