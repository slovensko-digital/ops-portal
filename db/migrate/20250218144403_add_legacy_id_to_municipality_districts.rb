class AddLegacyIdToMunicipalityDistricts < ActiveRecord::Migration[8.0]
  def change
    add_column :municipality_districts, :legacy_id, :integer
  end
end
