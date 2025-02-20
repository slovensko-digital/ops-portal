class AddLegacyIdToIssuesCommunications < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_communications, :legacy_id, :integer
    add_index :issues_communications, :legacy_id, unique: true
  end
end
