module Import
  class Issues::ImportStatesJob < ApplicationJob
    def perform
      Legacy::GenericModel.set_table_name("status")
      Legacy::GenericModel.find_in_batches do |group|
        group.each do |legacy_record|
          ::Issues::State.find_or_create_by!(
            legacy_id: legacy_record.id,
            name: legacy_record.status,
            color: legacy_record.color
          )
        end
      end
    end
  end
end
