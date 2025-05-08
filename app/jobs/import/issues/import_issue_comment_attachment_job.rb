module Import
  class Issues::ImportIssueCommentAttachmentJob < ApplicationJob
    include ImportMethods

    def perform(legacy_record, comment:)
      attachment_content = download_from_ops_portal(legacy_record.href)
      attachment_name = legacy_record.href

      persisted = attachment_persisted?(name: attachment_name, content: attachment_content, persisted_records: comment.attachments)

      comment.attachments.attach(io: attachment_content, filename: attachment_name) unless persisted
    end
  end
end
