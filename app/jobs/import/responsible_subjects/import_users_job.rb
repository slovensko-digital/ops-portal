module Import
  class ResponsibleSubjects::ImportUsersJob < ApplicationJob
    def perform
      Legacy::GenericModel.set_table_name('municipality_users')
      Legacy::GenericModel.find_in_batches do |group|
        group.each do |legacy_record|
          ::ResponsibleSubjects::User.find_or_initialize_by(
            id: legacy_record.id,
            deleted_at: legacy_record.deleted_at,
            # email: legacy_record.email, #  TODO skip emails for now
            gdpr_accepted: legacy_record.gdpr_accepted,
            # login: legacy_record.login, #  TODO skip emails for now
            name: legacy_record.name,
            organization_unit: ::ResponsibleSubjects::OrganizationUnit.find_by_id(legacy_record.org_unit_id),
            responsible_subject: ResponsibleSubject.find_by_id(legacy_record.zodpovednost_id),
            role_id: legacy_record.role_id,
          ).tap do |user|
            user.password =  legacy_record.password
            user.photo =  legacy_record.photo
            user.token =  legacy_record.remember_token
            user.tooltips = legacy_record.tooltips
            user.save!
          end
        end
      end
    end
  end
end
