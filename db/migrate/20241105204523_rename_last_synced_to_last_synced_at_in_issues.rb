class RenameLastSyncedToLastSyncedAtInIssues < ActiveRecord::Migration[8.0]
  def change
    rename_column :issues, :last_synced, :last_synced_at
  end
end
