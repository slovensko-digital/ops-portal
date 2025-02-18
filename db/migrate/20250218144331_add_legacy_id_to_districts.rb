class AddLegacyIdToDistricts < ActiveRecord::Migration[8.0]
  def change
    add_column :districts, :legacy_id, :integer
  end
end
