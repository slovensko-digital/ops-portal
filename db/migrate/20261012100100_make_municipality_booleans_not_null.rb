class MakeMunicipalityBooleansNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_default :municipalities, :active, from: nil, to: false
    change_column_default :municipalities, :has_municipality_districts, from: nil, to: false

    change_column_null :municipalities, :active, false
    change_column_null :municipalities, :has_municipality_districts, false
    change_column_null :municipalities, :archived, false
  end
end
