module Import
  class Issues::ImportIssueUpdatesJob < ApplicationJob
    include ImportHelper

    def perform(issue:)
      Legacy::GenericModel.set_table_name("alerts_updates")
      Legacy::GenericModel.where(alert: issue.id).find_in_batches do |group|
        group.each do |legacy_record|
          issue.updates.find_or_create_by!(
            id: legacy_record.id,
            added_at: convert_timestamp_value(legacy_record.ts),
            # email: legacy_record.email, TODO skip emails for now
            ip: legacy_record.ip,
            name: legacy_record.meno,
            published: legacy_record.status,
            text: legacy_record.text,
            author: User.find_by_id(legacy_record.updated_by),
            confirmed_by: User.find_by_id(legacy_record.confirmed_by)
          )
        end
      end
    end
  end
end
