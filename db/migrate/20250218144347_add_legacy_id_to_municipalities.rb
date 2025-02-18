class AddLegacyIdToMunicipalities < ActiveRecord::Migration[8.0]
  def change
    add_column :municipalities, :legacy_id, :integer
  end
end
