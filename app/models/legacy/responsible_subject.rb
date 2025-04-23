module Legacy
  class ResponsibleSubject < ::ApplicationRecord
    include ImportMethods

    def self.find_or_create_responsible_subject(legacy_id)
      return ::ResponsibleSubject.find_by(legacy_id: legacy_id) if ::ResponsibleSubject.find_by(legacy_id: legacy_id)

      Legacy::GenericModel.set_table_name("zodpovednost")
      legacy_record = Legacy::GenericModel.where.not(nazov: [ "Iné", "Iný subjekt" ]).find_by_id(legacy_id)

      if legacy_record
        self.create_responsible_subject_from_legacy_record(legacy_record)
      else
        self.find_or_create_other_responsible_subject
      end
    end

    def self.find_or_create_other_responsible_subject
      ::ResponsibleSubject.find_or_create_by!(
        responsible_subjects_type: ::ResponsibleSubjects::Type.find_by(name: "Iný subjekt"),
        subject_name: "Iný subjekt",
        name: "Iné"
      )
    end

    def self.create_responsible_subject_from_legacy_record(legacy_record)
      ::ResponsibleSubject.find_or_create_by!(
        legacy_id: legacy_record.id,
        active: legacy_record.status,
        code: legacy_record.code,
        email: legacy_record.email,
        name: legacy_record.meno,
        pro: legacy_record.pro,
        scope: legacy_record.scope,
        subject_name: legacy_record.nazov,
        district: ::District.find_by(legacy_id: legacy_record.kraj),
        municipality_district: ::MunicipalityDistrict.find_by(legacy_id: legacy_record.mestska_cast),
        municipality: ::Municipality.find_by(legacy_id: legacy_record.mesto),
        responsible_subjects_type: ::ResponsibleSubjects::Type.find_by(legacy_id: legacy_record.typ)
      )
    end
  end
end
