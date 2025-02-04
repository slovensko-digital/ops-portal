module Import
  class Issues::ImportIssueCommentsJob < ApplicationJob
    include ImportHelper

    def perform(issue:, import_images_job: Issues::ImportIssueCommentImagesJob)
      Legacy::GenericModel.set_table_name("comments")
      Legacy::GenericModel.where(remoteid: issue.id).find_in_batches do |group|
        group.each do |legacy_record|
          comment_activity = issue.activities.create!(
            type: 'Issues::CommentActivity'
          )
          comment = ::Issues::Comment.find_or_create_by!(
            id: legacy_record.id,
            added_at: convert_timestamp_value(legacy_record.time),
            # author_email: legacy_record.email, TODO skip emails for now
            author_name: legacy_record.meno,
            embed: legacy_record.embed.presence,
            image: legacy_record.image.presence,
            ip: legacy_record.ip,
            link: legacy_record.link.presence,
            published: legacy_record.is_published,
            state: legacy_record.status,
            text: legacy_record.komentar,
            verification: legacy_record.verification,
            activity: comment_activity,
            author_id: legacy_record.user.to_i.nonzero? || nil
          )

          import_images_job.perform_later(comment: comment)
        end
      end
    end
  end
end
