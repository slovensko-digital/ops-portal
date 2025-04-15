class FixIssueAddressFields < ActiveRecord::Migration[8.0]
  def change
    remove_column :issues_drafts, :address_neighbourhood, :string
    remove_column :issues_drafts, :address_town, :string
    remove_column :issues_drafts, :address_suburb, :string
    remove_column :issues_drafts, :address_state, :string
    remove_column :issues_drafts, :address_village, :string
    rename_column :issues_drafts, :address_road, :address_street
    rename_column :issues_drafts, :address_city_district, :address_municipality
    rename_column :issues_drafts, :address_county, :address_region

    remove_column :issues, :address_suburb, :string
    remove_column :issues, :address_village, :string
    remove_column :issues, :address_town, :string
    remove_column :issues, :address_state, :string

    rename_column :issues, :address_city_district, :address_municipality
    rename_column :issues, :address_county, :address_region

    add_column :issues, :address_country, :string
    add_column :issues, :address_country_code, :string
  end
end
