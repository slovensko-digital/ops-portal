module Import
  class ImportResponsibleSubjectsJob < ApplicationJob
    include ImportHelper

    def perform(import_responsible_subject_categories_job: ImportResponsibleSubjectCategoriesJob, chain_import: false, batch_size: 100)
      0.step do |offset|
        records_array = ImportHelper.with_another_db(ActiveRecord::Base.configurations.configs_for(env_name: 'odkaz_pre_starostu').first) do
          ActiveRecord::Base.connection.exec_query("SELECT * FROM zodpovednost LIMIT #{batch_size} OFFSET #{offset * batch_size}")
        end

        records_array.each do |record|
          responsible_subject = ResponsibleSubject.find_or_create_by(
            id: record['id'],
            active: record['status'],
            code: record['code'],
            email: record['email'],
            name: record['meno'],
            pro: record['pro'],
            scope: record['scope'],
            subject_name: record['nazov'],
            district_id: record['kraj'],
            municipality_district_id: record['mestska_cast'].to_i.nonzero? || nil,
            municipality_id: Municipality.find_by_id(record['mesto'])&.id,
            responsible_subject_type_id: record['typ']
          )

          import_responsible_subject_categories_job.perform_later(responsible_subject: responsible_subject) if chain_import
        end

        break if records_array.count < batch_size
      end
    end
  end
end
