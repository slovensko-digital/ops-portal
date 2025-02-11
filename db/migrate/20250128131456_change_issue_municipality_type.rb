class ChangeIssueMunicipalityType < ActiveRecord::Migration[8.0]
  def change
    remove_column :issues, :municipality, :string
    add_reference :issues, :municipality, null: false
  end
end
