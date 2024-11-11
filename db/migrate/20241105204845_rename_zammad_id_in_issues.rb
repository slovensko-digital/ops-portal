class RenameZammadIdInIssues < ActiveRecord::Migration[8.0]
  def change
    rename_column :issues, :zammad_id, :triage_external_id
  end
end
