class AddLastSyncedToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :last_synced, :datetime
  end
end
