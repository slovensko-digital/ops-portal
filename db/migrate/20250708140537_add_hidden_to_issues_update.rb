class AddHiddenToIssuesUpdate < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_updates, :hidden, :boolean, default: false
  end
end
