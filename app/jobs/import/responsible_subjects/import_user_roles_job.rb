module Import
  class ResponsibleSubjects::ImportUserRolesJob < ApplicationJob
    def perform(import_types_job: ResponsibleSubjects::ImportTypesJob, chain_import: false)
      Legacy::GenericModel.set_table_name("roles")
      Legacy::GenericModel.find_in_batches do |group|
        group.each do |legacy_record|
          ::ResponsibleSubjects::UserRole.find_or_create_by!(
            legacy_id: legacy_record.id,
            slug: legacy_record.slug,
            name: legacy_record.name,
          )
        end
      end

      import_types_job.perform_later(chain_import: chain_import) if chain_import
    end
  end
end
