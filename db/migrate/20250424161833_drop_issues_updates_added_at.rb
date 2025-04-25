class DropIssuesUpdatesAddedAt < ActiveRecord::Migration[8.0]
  def change
    remove_column :issues_updates, :added_at, :datetime
  end
end
