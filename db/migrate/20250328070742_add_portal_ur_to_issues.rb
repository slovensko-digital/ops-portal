class AddPortalUrToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :portal_url, :string
  end
end
