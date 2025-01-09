module Import
  class ImportDistrictsJob < ApplicationJob
    include ImportHelper

    def perform(import_municipalities_job: ImportMunicipalitiesJob, chain_import: false)
      records_array = ImportHelper.with_another_db(ActiveRecord::Base.configurations.configs_for(env_name: 'odkaz_pre_starostu').first) do
        ActiveRecord::Base.connection.exec_query('SELECT * FROM kraje')
      end

      records_array.each do |record|
        District.find_or_create_by(
          id: record['id'],
          name: record['nazov_kraju']
        )
      end

      import_municipalities_job.perform_later(chain_import: chain_import) if chain_import
    end
  end
end
