class AddLastActivityAtToIssues < ActiveRecord::Migration[7.1]
  def change
    add_column :issues, :last_activity_at, :datetime
    add_index :issues, :last_activity_at, order: { last_activity_at: "DESC NULLS LAST" }
  end
end
