module Import
  class Issues::ImportIssueCommentAttachmentsJob < ApplicationJob
    queue_with_priority 100

    include ImportMethods

    def perform(comment:)
      Issue.transaction do
        hrefs = Legacy::Alerts::CommentAttachment.where(comment_id: comment.legacy_comment_id).pluck(:href)
        comment.attachments.attach(download_attachables_from_ops_portal(hrefs))
      end
    end
  end
end
