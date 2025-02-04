module Import
  class ImportResponsibleSubjectsJob < ApplicationJob
    def perform(import_categories_job: ResponsibleSubjects::ImportCategoriesJob, import_organization_units_job: ResponsibleSubjects::ImportOrganizationUnitsJob, import_users_job: ResponsibleSubjects::ImportUsersJob, chain_import: false)
      Legacy::GenericModel.set_table_name("zodpovednost")
      Legacy::GenericModel.find_in_batches do |group|
        group.each do |legacy_record|
          ResponsibleSubject.find_or_create_by!(
            id: legacy_record.id,
            active: legacy_record.status,
            code: legacy_record.code,
            email: legacy_record.email,
            name: legacy_record.meno,
            pro: legacy_record.pro,
            scope: legacy_record.scope,
            subject_name: legacy_record.nazov,
            district_id: legacy_record.kraj,
            municipality_district_id: legacy_record.mestska_cast.to_i.nonzero? || nil,
            municipality_id: Municipality.find_by_id(legacy_record.mesto)&.id,
            responsible_subjects_type_id: legacy_record.typ
          )
        end
      end

      if chain_import
        import_categories_job.perform_later
        import_organization_units_job.perform_later
        import_users_job.perform_later
      end
    end
  end
end
