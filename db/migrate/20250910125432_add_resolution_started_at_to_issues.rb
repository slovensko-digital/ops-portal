class AddResolutionStartedAtToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :resolution_started_at, :datetime
    add_index :issues, :resolution_started_at
  end
end
