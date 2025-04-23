module Import
  class Issues::ImportIssueUpdateAttachmentsJob < ApplicationJob
    include ImportMethods

    def perform(update:)
      Legacy::Alerts::UpdateImage.where(update_id: update.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          attachment_content = download_from_ops_portal(legacy_record.href)
          attachment_name = File.basename(legacy_record.href)

          persisted = attachment_persisted?(name: attachment_name, content: attachment_content, persisted_records: update.attachments)

          update.attachments.attach(io: attachment_content, filename: attachment_name) unless persisted
        end
      end
    end
  end
end
