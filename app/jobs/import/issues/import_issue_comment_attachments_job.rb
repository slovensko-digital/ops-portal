module Import
  class Issues::ImportIssueCommentAttachmentsJob < ApplicationJob
    def perform(comment:, import_attachment_job: Issues::ImportIssueCommentAttachmentJob)
      Legacy::Alerts::CommentAttachment.where(comment_id: comment.legacy_comment_id).find_in_batches do |group|
        group.each do |legacy_record|
          import_attachment_job.perform_later(legacy_record, comment: comment)
        end
      end
    end
  end
end
