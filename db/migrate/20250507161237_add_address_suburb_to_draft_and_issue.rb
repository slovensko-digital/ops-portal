class AddAddressSuburbToDraftAndIssue < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :address_suburb, :string
    add_column :issues_drafts, :address_suburb, :string
  end
end
