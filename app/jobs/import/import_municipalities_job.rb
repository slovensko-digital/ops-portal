module Import
  class Import::ImportMunicipalitiesJob < ApplicationJob
    include ImportHelper

    def perform(import_municipality_districts_job: ImportMunicipalityDistrictsJob, import_streets_job: ImportStreetsJob, chain_import: false)
      records_array = ImportHelper.with_another_db(ActiveRecord::Base.configurations.configs_for(env_name: 'odkaz_pre_starostu').first) do
        ActiveRecord::Base.connection.exec_query('SELECT * FROM mesta')
      end

      records_array.each do |record|
        municipality = Municipality.find_or_create_by!(
          id: record['id'],
          active: record['status'],
          alias: record['alias'],
          category: record['city_type'],
          email: record['email'],
          handled_by: record['handled_by'],
          has_municipality_districts: record['mestske_casti'],
          languages: record['languages'],
          latitude: record['map_y'],
          logo: record['logo'],
          longitude: record['map_x'],
          municipality_type: record['typ'],
          name: record['nazov'],
          population: record['pocet_obyvatelov'],
          sub: record['sub'],
          district_id: record['kraj']
        )

        next unless chain_import

        if municipality.has_municipality_districts
          import_municipality_districts_job.perform_later(municipality: municipality, chain_import: chain_import)
        else
          import_streets_job.perform_later(municipality: municipality)
        end
      end
    end
  end
end
