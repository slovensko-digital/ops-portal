class AddMoreAddressFieldsToDrafts < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_drafts, :address_county, :string
  end
end
