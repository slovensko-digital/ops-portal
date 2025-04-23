module Import
  class Issues::ImportIssueCommunicationAttachmentsJob < ApplicationJob
    include ImportMethods

    def perform(communication:)
      Legacy::Alerts::CommunicationAttachment.where(communication_id: communication.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          attachment_content = download_from_ops_portal(legacy_record.path)
          attachment_name = legacy_record.name

          persisted = attachment_persisted?(name: attachment_name, content: attachment_content, persisted_records: communication.attachments)

          communication.attachments.attach(io: attachment_content, filename: attachment_name) unless persisted
        end
      end
    end
  end
end
