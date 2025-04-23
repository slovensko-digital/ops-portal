class DropIssuesCommentsEmptyAttributes < ActiveRecord::Migration[8.0]
  def change
    remove_column :issues_comments, :embed, :string
    remove_column :issues_comments, :image, :string
    remove_column :issues_comments, :link, :string
    remove_column :issues_comments, :state, :boolean
  end
end
