class AddEffectiveAtToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :effective_at, :datetime, as: "COALESCE(resolution_started_at, created_at)", stored: true
    add_index :issues, :effective_at
  end
end
