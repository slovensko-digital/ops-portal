class AddMunicipalityDistrictIdToIssues < ActiveRecord::Migration[8.0]
  def change
    add_reference :issues, :municipality_district, null: true, foreign_key: true
  end
end
