module Import
  class Issues::ImportStatesJob < ApplicationJob
    def perform
      Legacy::Status.find_in_batches do |group|
        group.each do |legacy_record|
          ::Issues::State.find_or_initialize_by(name: legacy_record.status).tap do |state|
            state.legacy_id = legacy_record.id
            state.color = legacy_record.color

            state.save!
          end
        end
      end
    end
  end
end
