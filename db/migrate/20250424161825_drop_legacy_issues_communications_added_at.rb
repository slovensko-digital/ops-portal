class DropLegacyIssuesCommunicationsAddedAt < ActiveRecord::Migration[8.0]
  def change
    remove_column :legacy_issues_communications, :added_at, :datetime
  end
end
