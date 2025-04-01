class AddAuthorToIssuesCommunication < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_communications, :author_id, :bigint
    add_column :issues_communications, :author_type, :string
  end
end
