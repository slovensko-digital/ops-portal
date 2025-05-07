class MigrateAliasToAliasesArray < ActiveRecord::Migration[8.0]
  def up
    add_column :municipalities, :aliases, :string, array: true, default: [], null: false
    add_column :municipality_districts, :aliases, :string, array: true, default: [], null: false

    Municipality.reset_column_information
    MunicipalityDistrict.reset_column_information

    Municipality.find_each { |m|  m.update_columns(aliases: [ m.alias, m.name ].compact) }
    MunicipalityDistrict.find_each { |md| md.update_columns(aliases: [ md.alias, md.name ].compact) }

    remove_column :municipalities, :alias
    remove_column :municipality_districts, :alias
  end

  def down
    add_column :municipalities, :alias, :string
    add_column :municipality_districts, :alias, :string

    Municipality.reset_column_information
    MunicipalityDistrict.reset_column_information

    Municipality.find_each { |m| m.update_columns(alias: m.aliases&.first) }
    MunicipalityDistrict.find_each { |md| md.update_columns(alias: md.aliases&.first) }

    remove_column :municipalities, :aliases
    remove_column :municipality_districts, :aliases
  end
end
