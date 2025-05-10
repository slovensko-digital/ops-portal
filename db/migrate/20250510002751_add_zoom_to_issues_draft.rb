class AddZoomToIssuesDraft < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_drafts, :zoom, :integer
  end
end
