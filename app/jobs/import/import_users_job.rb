module Import
  class ImportUsersJob < ApplicationJob
    include ImportHelper

    def perform
      Legacy::GenericModel.set_table_name("users")
      Legacy::GenericModel.find_in_batches do |group|
        group.each do |legacy_record|
          User.find_or_create_by!(
            id: legacy_record.id,
            about: legacy_record.about,
            access_token: legacy_record.access_token,
            active: legacy_record.status,
            admin_name: legacy_record.admin_name,
            anonymous: legacy_record.anonymous,
            banned: legacy_record.is_banned,
            birth: legacy_record.birth,
            created_from_app: legacy_record.created_from_app,
            email: generate_dummy_email(legacy_record.id), # TODO skip emails for now
            # email: legacy_record.email, # TODO skip emails for now
            email_notifiable: legacy_record.email_notification,
            exp: legacy_record.exp,
            fcm_token: legacy_record.fcm_token,
            firstname: legacy_record.meno,
            gdpr_accepted: legacy_record.gdpr_accepted,
            lastname: legacy_record.priezvisko.presence,
            legacy_rights: convert_legacy_rights_value(legacy_record.rights),
            login: legacy_record.login,
            organization: legacy_record.is_organization,
            password: legacy_record.password,
            phone: legacy_record.telefon,
            resident: legacy_record.residency,
            sex: legacy_record.sex,
            signature: legacy_record.signature,
            timestamp: convert_timestamp_value(legacy_record.timestamp),
            verification: legacy_record.verification,
            verified: legacy_record.verified,
            city_id: legacy_record.cityid,
            municipality: Municipality.find_by_id(legacy_record.mesto),
            street: Street.find_by_id(legacy_record.streetid)
          )
        end
      end
    end

    private

    def convert_legacy_rights_value(value)
      case value
      when "A"
        1
      when "Ax"
        2
      when "U"
        3
      end
    end
  end
end
