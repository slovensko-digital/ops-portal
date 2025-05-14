module Legacy
  class User < ::ApplicationRecord
    include ImportMethods

    def self.find_or_create_user(legacy_id)
      return unless legacy_id
      return ::User.find_by(legacy_id: legacy_id) if ::User.find_by(legacy_id: legacy_id)

      legacy_record = Legacy::OldUser.where(rights: "U").find_by_id(legacy_id)
      self.create_user_from_legacy_record(legacy_record) if legacy_record
    end

    def self.find_or_create_agent(legacy_id)
      return unless legacy_id
      return Legacy::Agent.find_by(legacy_id: legacy_id) if Legacy::Agent.find_by(legacy_id: legacy_id)

      legacy_record = Legacy::OldUser.where(rights: %w[A Ax]).find_by_id(legacy_id)
      self.create_agent_from_legacy_record(legacy_record) if legacy_record
    end

    def self.find_or_create_responsible_subjects_user(legacy_id)
      return unless legacy_id
      return ::ResponsibleSubjects::User.find_by(legacy_id: legacy_id) if ::ResponsibleSubjects::User.find_by(legacy_id: legacy_id)

      legacy_record = Legacy::MunicipalityUser.find_by_id(legacy_id)
      self.create_responsible_subjects_user_from_legacy_record(legacy_record) if legacy_record
    end

    def self.create_user_from_legacy_record(legacy_record)
      ::User.find_or_create_by!(self.user_params(legacy_record))
    end

    def self.create_agent_from_legacy_record(legacy_record)
      Legacy::Agent.find_or_create_by!(self.user_params(legacy_record).merge!({ rights: convert_legacy_rights_value(legacy_record.rights) }))
    end

    def self.create_responsible_subjects_user_from_legacy_record(legacy_record)
      ::ResponsibleSubjects::User.find_or_create_by!(self.responsible_subjects_user_params(legacy_record))
    end

    def self.user_params(legacy_record)
      {
        legacy_id: legacy_record.id,
        about: legacy_record.about,
        access_token: legacy_record.access_token,
        active: legacy_record.status,
        admin_name: legacy_record.admin_name,
        anonymous: legacy_record.anonymous,
        banned: legacy_record.is_banned,
        birth: legacy_record.birth,
        created_from_app: legacy_record.created_from_app,
        email: ENV["EMAILS_IMPORT"] == "ON" ? legacy_record.email : generate_dummy_email(legacy_record.id),
        email_notifiable: legacy_record.email_notification,
        exp: legacy_record.exp,
        fcm_token: legacy_record.fcm_token,
        firstname: legacy_record.meno,
        gdpr_accepted: legacy_record.gdpr_accepted,
        lastname: legacy_record.priezvisko.presence,
        login: legacy_record.login,
        organization: legacy_record.is_organization,
        password_hash: generate_dummy_password,
        phone: legacy_record.telefon,
        resident: legacy_record.residency,
        sex: legacy_record.sex,
        signature: legacy_record.signature,
        timestamp: Time.at(legacy_record.timestamp).to_datetime,
        verification: legacy_record.verification,
        verified: legacy_record.verified,
        city_id: legacy_record.cityid,
        municipality: ::Municipality.find_by(legacy_id: legacy_record.mesto),
        street: ::Street.find_by(legacy_id: legacy_record.streetid),
        onboarded: true,
        status: "verified"
      }
    end

    def self.responsible_subjects_user_params(legacy_record)
      {
        legacy_id: legacy_record.id,
        deleted_at: legacy_record.deleted_at,
        email: ENV["EMAILS_IMPORT"] == "ON" ? legacy_record.email : generate_dummy_email(legacy_record.id),
        gdpr_accepted: legacy_record.gdpr_accepted,
        login: legacy_record.login,
        name: legacy_record.name,
        photo: legacy_record.photo,
        token: legacy_record.remember_token,
        tooltips: legacy_record.tooltips,
        organization_unit: ::ResponsibleSubjects::OrganizationUnit.find_by(legacy_id: legacy_record.org_unit_id),
        responsible_subject: ::ResponsibleSubject.find_by(legacy_id: legacy_record.zodpovednost_id),
        role: ::ResponsibleSubjects::UserRole.find_by(legacy_id: legacy_record.role_id)
      }
    end

    def self.generate_dummy_email(id)
      "#{id}@localhost.dev"
    end

    def self.generate_dummy_password
      BCrypt::Password.create(Random.uuid)
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
