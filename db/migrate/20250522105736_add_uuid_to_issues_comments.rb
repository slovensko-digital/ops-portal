class AddUuidToIssuesComments < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_comments, :uuid, :uuid
    add_index :issues_comments, :uuid, unique: true
  end
end
