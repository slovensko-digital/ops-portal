class AddLegacyIdToStreets < ActiveRecord::Migration[8.0]
  def change
    add_column :streets, :legacy_id, :integer
  end
end
