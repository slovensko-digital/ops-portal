class AddWhitelistedStreetsToMunicipalities < ActiveRecord::Migration[8.0]
  def change
    add_column :municipalities, :whitelisted_streets, :string, array: true, default: []
  end
end
