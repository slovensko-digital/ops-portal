module Import
  class ImportLabelsJob < ApplicationJob
    queue_with_priority 100

    def perform
      Legacy::OldLabel.find_each do |legacy_record|
        ::Legacy::Label.find_or_create_by!(
          legacy_id: legacy_record.id,
          name: legacy_record.text,
          color: legacy_record.color,
          responsible_subject: ResponsibleSubject.find_by(legacy_id: legacy_record.zodpovednost_id)
        )
      end
    end
  end
end
