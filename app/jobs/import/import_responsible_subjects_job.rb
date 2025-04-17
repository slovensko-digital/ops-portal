module Import
  class ImportResponsibleSubjectsJob < ApplicationJob
    def perform(
      import_categories_job: ResponsibleSubjects::ImportCategoriesJob,
      import_organization_units_job: ResponsibleSubjects::ImportOrganizationUnitsJob,
      import_users_job: ResponsibleSubjects::ImportUsersJob,
      chain_import: false
    )
      Legacy::OldResponsibleSubject.where.not(nazov: [ "Iné", "Iný subjekt" ]).find_in_batches do |group|
        group.each do |legacy_record|
          Legacy::ResponsibleSubject.create_responsible_subject_from_legacy_record(legacy_record)
        end
      end

      Legacy::ResponsibleSubject.find_or_create_other_responsible_subject

      if chain_import
        import_categories_job.perform_later
        import_organization_units_job.perform_later
        import_users_job.perform_later
      end
    end
  end
end
