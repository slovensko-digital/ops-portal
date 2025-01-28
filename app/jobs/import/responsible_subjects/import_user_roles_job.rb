module Import
  class ResponsibleSubjects::ImportUserRolesJob < ApplicationJob
    def perform
      Legacy::GenericModel.set_table_name("roles")
      Legacy::GenericModel.find_in_batches do |group|
        group.each do |legacy_record|
          ::ResponsibleSubjects::UserRole.find_or_create_by!(
            id: legacy_record.id,
            slug: legacy_record.slug,
            name: legacy_record.name,
          )
        end
      end
    end
  end
end
