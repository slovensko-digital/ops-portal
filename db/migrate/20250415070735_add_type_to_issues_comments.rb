class AddTypeToIssuesComments < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_comments, :type, :string
  end
end
