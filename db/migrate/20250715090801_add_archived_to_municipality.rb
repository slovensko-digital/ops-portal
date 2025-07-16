class AddArchivedToMunicipality < ActiveRecord::Migration[8.0]
  def change
    add_column :municipalities, :archived, :boolean, default: false
    add_column :municipality_districts, :archived, :boolean, default: false
  end
end
