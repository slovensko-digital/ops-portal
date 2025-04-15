module Import
  class ResponsibleSubjects::ImportUsersJob < ApplicationJob
    include ImportMethods

    def perform
      Legacy::GenericModel.set_table_name("municipality_users")
      Legacy::GenericModel.find_in_batches do |group|
        group.each do |legacy_record|
          ::ResponsibleSubjects::User.find_or_create_by!(
            legacy_id: legacy_record.id,
            deleted_at: legacy_record.deleted_at,
            email: Legacy::User.generate_dummy_email(legacy_record.id), # TODO skip emails for now
            # email: legacy_record.email, # TODO skip emails for now
            gdpr_accepted: legacy_record.gdpr_accepted,
            login: Legacy::User.generate_dummy_email(legacy_record.id), # TODO skip emails for now
            # login: legacy_record.login, # TODO skip emails for now
            name: legacy_record.name,
            password: Legacy::User.generate_dummy_password,
            photo: legacy_record.photo,
            token: legacy_record.remember_token,
            tooltips: legacy_record.tooltips,
            organization_unit: ::ResponsibleSubjects::OrganizationUnit.find_by(legacy_id: legacy_record.org_unit_id),
            responsible_subject: ::ResponsibleSubject.find_by(legacy_id: legacy_record.zodpovednost_id),
            role: ::ResponsibleSubjects::UserRole.find_by(legacy_id: legacy_record.role_id)
          )
        end
      end
    end
  end
end
