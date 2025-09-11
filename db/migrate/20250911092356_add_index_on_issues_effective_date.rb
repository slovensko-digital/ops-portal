class AddIndexOnIssuesEffectiveDate < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :issues, "(COALESCE(resolution_started_at, created_at))",
              name: "index_issues_on_effective_date", algorithm: :concurrently
  end
end
