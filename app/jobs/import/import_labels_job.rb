module Import
  class ImportLabelsJob < ApplicationJob
    queue_with_priority 100

    def perform
      Legacy::OldLabel.find_each do |legacy_record|
        ::Legacy::Label.create_from_legacy_record(legacy_record)
      end
    end
  end
end
