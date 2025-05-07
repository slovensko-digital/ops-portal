class MigrateAliasToAliasesArray < ActiveRecord::Migration[8.0]
  def up
    add_column :municipalities, :aliases, :string, array: true, default: [], null: false
    add_column :municipality_districts, :aliases, :string, array: true, default: [], null: false

    Municipality.reset_column_information
    Municipality.where.not(alias: nil).update_all("aliases = ARRAY[alias]")
    MunicipalityDistrict.where.not(alias: nil).update_all("aliases = ARRAY[alias]")

    remove_column :municipalities, :alias
    remove_column :municipality_districts, :alias
  end

  def down
    add_column :municipalities, :alias, :string
    add_column :municipality_districts, :alias, :string

    Municipality.reset_column_information
    Municipality.find_each do |m|
      m.update_columns(alias: m.aliases&.first)
    end

    MunicipalityDistrict.find_each do |md|
      md.update_columns(alias: md.aliases&.first)
    end

    remove_column :municipalities, :aliases
    remove_column :municipality_districts, :aliases
  end
end
