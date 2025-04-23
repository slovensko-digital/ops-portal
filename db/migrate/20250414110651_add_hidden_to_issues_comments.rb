class AddHiddenToIssuesComments < ActiveRecord::Migration[8.0]
  def change
    remove_column :issues_comments, :published, :boolean
    add_column :issues_comments, :hidden, :boolean, default: false
  end
end
