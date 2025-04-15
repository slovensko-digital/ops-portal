class AddAddressDistrictToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :address_district, :string
    add_column :issues_drafts, :address_district, :string
  end
end
