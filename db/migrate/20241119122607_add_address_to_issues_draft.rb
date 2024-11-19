class AddAddressToIssuesDraft < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_drafts, :address_house_number, :string
    add_column :issues_drafts, :address_road, :string
    add_column :issues_drafts, :address_neighbourhood, :string
    add_column :issues_drafts, :address_town, :string
    add_column :issues_drafts, :address_suburb, :string
    add_column :issues_drafts, :address_city_district, :string
    add_column :issues_drafts, :address_city, :string
    add_column :issues_drafts, :address_state, :string
    add_column :issues_drafts, :address_postcode, :string
    add_column :issues_drafts, :address_country, :string
    add_column :issues_drafts, :address_country_code, :string
    add_column :issues_drafts, :address_village, :string
  end
end
