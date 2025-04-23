module Import
  class ResponsibleSubjects::ImportTypesJob < ApplicationJob
    def perform(import_responsible_subjects_job: Import::ImportResponsibleSubjectsJob, chain_import: false)
      Legacy::ResponsibleSubjects::Type.find_in_batches do |group|
        group.each do |legacy_record|
          ::ResponsibleSubjects::Type.find_or_create_by!(
            legacy_id: legacy_record.id,
            active: legacy_record.status,
            name: legacy_record.nazov,
          )
        end
      end

      import_responsible_subjects_job.perform_later(chain_import: chain_import) if chain_import
    end
  end
end
