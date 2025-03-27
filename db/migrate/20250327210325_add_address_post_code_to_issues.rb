class AddAddressPostCodeToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :address_postcode, :string
  end
end
