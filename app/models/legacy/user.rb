module Legacy
  class User < ::ApplicationRecord
    include ImportMethods

    def self.find_or_create_user(posted_by)
      return ::User.find_by(legacy_id: posted_by) if ::User.find_by(legacy_id: posted_by)

      Legacy::GenericModel.set_table_name("users")
      legacy_record = Legacy::GenericModel.find_by_id(posted_by)
      self.create_user_from_legacy_record(legacy_record) if legacy_record
    end

    def self.create_user_from_legacy_record(legacy_record)
      ::User.find_or_create_by!(
        legacy_id: legacy_record.id,
        about: legacy_record.about,
        access_token: legacy_record.access_token,
        active: legacy_record.status,
        admin_name: legacy_record.admin_name,
        anonymous: legacy_record.anonymous,
        banned: legacy_record.is_banned,
        birth: legacy_record.birth,
        created_from_app: legacy_record.created_from_app,
        email: self.generate_dummy_email(legacy_record.id), # TODO skip emails for now
        # email: legacy_record.email, # TODO skip emails for now
        email_notifiable: legacy_record.email_notification,
        exp: legacy_record.exp,
        fcm_token: legacy_record.fcm_token,
        firstname: legacy_record.meno,
        gdpr_accepted: legacy_record.gdpr_accepted,
        lastname: legacy_record.priezvisko.presence,
        legacy_rights: self.convert_legacy_rights_value(legacy_record.rights),
        login: legacy_record.login,
        organization: legacy_record.is_organization,
        password: legacy_record.password,
        phone: legacy_record.telefon,
        resident: legacy_record.residency,
        sex: legacy_record.sex,
        signature: legacy_record.signature,
        timestamp: Time.at(legacy_record.timestamp).to_datetime,
        verification: legacy_record.verification,
        verified: legacy_record.verified,
        city_id: legacy_record.cityid,
        municipality: ::Municipality.find_by(legacy_id: legacy_record.mesto),
        street: ::Street.find_by(legacy_id: legacy_record.streetid)
      )
    end

    def self.generate_dummy_email(id)
      "#{id}@localhost.dev"
    end

    def self.convert_legacy_rights_value(value)
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
