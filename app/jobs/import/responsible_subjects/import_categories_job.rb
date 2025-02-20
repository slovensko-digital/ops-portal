module Import
  class ResponsibleSubjects::ImportCategoriesJob < ApplicationJob
    def perform
      Legacy::GenericModel.set_table_name("zodpovednost_kategorie")
      Legacy::GenericModel.find_in_batches do |group|
        group.each do |legacy_record|
          ::ResponsibleSubjects::Category.find_or_create_by!(
            legacy_id: legacy_record.id,
            responsible_subject: ::ResponsibleSubject.find_by_id(legacy_record.id_zodpovednost),
            issues_category: ::Issues::Category.find_by(legacy_id: legacy_record.id_kategoria),
          )
        end
      end
    end
  end
end
