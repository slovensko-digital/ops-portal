module Import
  class Issues::ImportStatesJob < ApplicationJob
    queue_with_priority 100

    def perform
      Legacy::Status.find_in_batches do |group|
        group.each do |legacy_record|
          name = legacy_record.status
          name = "Zamietnutý" if legacy_record.status == "Neprijatý"
          ::Issues::State.find_or_initialize_by(name: name).tap do |state|
            state.legacy_id = legacy_record.id
            state.color = legacy_record.color

            state.save!
          end
        end
      end
    end
  end
end
