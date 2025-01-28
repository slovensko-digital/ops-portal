module Import
  class ImportUsersJob < ApplicationJob
    include ImportHelper

    def perform
      Legacy::GenericModel.set_table_name('users')
      Legacy::GenericModel.find_in_batches do |group|
        group.each do |legacy_record|
          User.find_or_initialize_by(
            id: legacy_record.id,
            admin_name: legacy_record.admin_name,
            anonymous: legacy_record.anonymous,
            birth: legacy_record.birth,
            created_from_app: legacy_record.created_from_app,
            # email: legacy_record.email, #  TODO skip emails for now
            exp: legacy_record.exp,
            fcm_token: legacy_record.fcm_token,
            legacy_rights: convert_legacy_rights_value(legacy_record.rights),
            login: legacy_record.login,
            organization: legacy_record.is_organization
          ).tap do |user|
            user.about = legacy_record.about
            user.access_token = legacy_record.access_token
            user.active = legacy_record.status
            user.banned = legacy_record.is_banned
            user.email_notifiable = legacy_record.email_notification
            user.firstname = legacy_record.meno
            user.gdpr_accepted = legacy_record.gdpr_accepted
            user.lastname = legacy_record.priezvisko
            user.password = legacy_record.password
            user.phone = legacy_record.telefon
            user.resident = legacy_record.residency
            user.sex = legacy_record.sex
            user.signature = legacy_record.signature
            user.timestamp = convert_timestamp_value(legacy_record.timestamp)
            user.verification = legacy_record.verification
            user.verified = legacy_record.verified
            user.city_id = legacy_record.cityid
            user.municipality = Municipality.find_by_id(legacy_record.mesto)
            user.street = Street.find_by_id(legacy_record.streetid)

            user.save!
          end
        end
      end
    end

    private

    def convert_legacy_rights_value(value)
      case value
      when 'A'
        1
      when 'Ax'
        2
      when 'U'
        3
      end
    end
  end
end
