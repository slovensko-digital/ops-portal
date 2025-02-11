class CreateMunicipalityDistricts < ActiveRecord::Migration[8.0]
  def change
    create_table :municipality_districts do |t|
      t.string :name
      t.references :municipality, null: false, foreign_key: true
      t.string :alias
      t.string :genitiv
      t.string :lokal
      t.string :description
      t.string :logo

      t.timestamps
    end
  end
end
