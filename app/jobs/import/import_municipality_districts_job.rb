module Import
  class Import::ImportMunicipalityDistrictsJob < ApplicationJob
    include ImportHelper

    def perform(municipality:, import_streets_job: ImportStreetsJob, chain_import: false)
      records_array = ImportHelper.with_another_db(ActiveRecord::Base.configurations.configs_for(env_name: 'odkaz_pre_starostu').first) do
        ActiveRecord::Base.connection.exec_query("SELECT * FROM mestske_casti where mesto = #{municipality.id}")
      end

      records_array.each do |record|
        municipality.municipality_districts.find_or_create_by(
          id: record['id'],
          alias: record['alias'],
          description: record['popis'].presence,
          genitiv: record['genitiv'],
          logo: record['logo'],
          lokal: record['lokal'],
          name: record['nazov'],
          municipality_id: record['mesto']
        )
      end

      import_streets_job.perform_later(municipality: municipality) if chain_import
    end
  end
end
