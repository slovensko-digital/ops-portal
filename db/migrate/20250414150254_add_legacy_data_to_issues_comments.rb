class AddLegacyDataToIssuesComments < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_comments, :legacy_data, :jsonb
  end
end
