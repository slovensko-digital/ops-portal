module Import
  class Issues::ImportIssueCommentAttachmentsJob < ApplicationJob
    include ImportMethods

    def perform(comment:)
      Legacy::GenericModel.set_table_name("media_comments")
      Legacy::GenericModel.where(comment_id: comment.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          attachment_content = download_from_ops_portal(legacy_record.href)
          attachment_name = legacy_record.href

          persisted = comment.attachments_attachments.includes(:blob).where(blob: { filename: attachment_name, byte_size: attachment_content.size }).any?

          comment.attachments.attach(io: attachment_content, filename: attachment_name) unless persisted
        end
      end
    end
  end
end
