module Import
  class Issues::ImportIssueCommunicationAttachmentsJob < ApplicationJob
    include ImportMethods

    def perform(communication:)
      Legacy::GenericModel.set_table_name("communication_attachments")
      Legacy::GenericModel.where(communication_id: communication.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          attachment_content = download_from_ops_portal(legacy_record.path)
          attachment_name = legacy_record.name

          persisted = communication.attachments_attachments.includes(:blob).where(blob: { filename: attachment_name, byte_size: attachment_content.size }).any?

          communication.attachments.attach(io: attachment_content, filename: attachment_name) unless persisted
        end
      end
    end
  end
end
