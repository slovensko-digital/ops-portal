module Import
  class Issues::ImportIssueUpdateAttachmentsJob < ApplicationJob
    include ImportMethods

    def perform(update:)
      Legacy::GenericModel.set_table_name("media_updates")
      Legacy::GenericModel.where(update_id: update.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          attachment_content = download_from_ops_portal(legacy_record.href)
          attachment_name = File.basename(legacy_record.href)

          persisted = update.attachments_attachments.includes(:blob).where(blob: { filename: attachment_name, byte_size: attachment_content.size }).any?

          update.attachments.attach(io: attachment_content, filename: attachment_name) unless persisted
        end
      end
    end
  end
end
