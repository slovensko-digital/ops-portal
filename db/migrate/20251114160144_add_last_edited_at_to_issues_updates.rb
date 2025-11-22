class AddLastEditedAtToIssuesUpdates < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_updates, :last_edited_at, :datetime
  end
end
