class AddAddressFieldsToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :address_state, :string
    add_column :issues, :address_county, :string
    add_column :issues, :address_city, :string
    add_column :issues, :address_city_district, :string
    add_column :issues, :address_suburb, :string
    add_column :issues, :address_village, :string
    add_column :issues, :address_town, :string
    add_column :issues, :address_road, :string
    add_column :issues, :address_house_number, :string
  end
end
