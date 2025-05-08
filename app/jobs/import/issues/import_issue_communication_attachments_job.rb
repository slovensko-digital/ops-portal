module Import
  class Issues::ImportIssueCommunicationAttachmentsJob < ApplicationJob
    def perform(communication:, import_attachment_job: Issues::ImportIssueCommunicationAttachmentJob)
      Legacy::Alerts::CommunicationAttachment.where(communication_id: communication.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          import_attachment_job.perform_later(legacy_record, communication: communication)
        end
      end
    end
  end
end
