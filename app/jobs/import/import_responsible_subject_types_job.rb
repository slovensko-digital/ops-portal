module Import
  class ImportResponsibleSubjectTypesJob < ApplicationJob
    include ImportHelper

    def perform(import_responsible_subjects_job: ImportResponsibleSubjectsJob, chain_import: false)
      records_array = ImportHelper.with_another_db(ActiveRecord::Base.configurations.configs_for(env_name: 'odkaz_pre_starostu').first) do
        ActiveRecord::Base.connection.exec_query("SELECT * FROM zodpovednost_typy")
      end

      records_array.each do |record|
        ResponsibleSubjectType.find_or_create_by(
          id: record['id'],
          active: record['status'],
          name: record['nazov'],
        )
      end

      import_responsible_subjects_job.perform_later(chain_import: chain_import) if chain_import
    end
  end
end
