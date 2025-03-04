module Import
  class Issues::ImportIssueCommentAttachmentsJob < ApplicationJob
    include ImportMethods

    def perform(comment:)
      Legacy::GenericModel.set_table_name("media_comments")
      Legacy::GenericModel.where(comment_id: comment.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          comment.attachments.attach(io: download_from_ops_portal(legacy_record.href), filename: File.basename(legacy_record.href))
        end
      end
    end
  end
end
