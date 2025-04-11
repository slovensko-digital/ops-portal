class AddAddressDataToIssuesDrafts < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_drafts, :address_data, :jsonb
  end
end
