module Import
  class Issues::ImportIssueUpdateAttachmentsJob < ApplicationJob
    include ImportMethods

    def perform(update:, import_attachment_job: Issues::ImportIssueUpdateAttachmentJob)
      Legacy::Alerts::UpdateImage.where(update_id: update.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          import_attachment_job.perform_later(legacy_record, update: update)
        end
      end
    end
  end
end
