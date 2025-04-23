module Import
  class ResponsibleSubjects::ImportOrganizationUnitsJob < ApplicationJob
    def perform
      Legacy::OrganizationalUnit.find_in_batches do |group|
        group.each do |legacy_record|
          ::ResponsibleSubjects::OrganizationUnit.find_or_create_by!(
            legacy_id: legacy_record.id,
            responsible_subject: ResponsibleSubject.find_by(legacy_id: legacy_record.zodpovednost_id)
          )
        end
      end
    end
  end
end
