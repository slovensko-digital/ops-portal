module Import
  class Issues::ImportIssueCommentsJob < ApplicationJob
    include ImportMethods

    def perform(issue:, import_photos_job: Issues::ImportIssueCommentAttachmentsJob)
      Legacy::GenericModel.set_table_name("comments")
      Legacy::GenericModel.where(remoteid: issue.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          comment = ::Issues::Comment.find_or_initialize_by(
            legacy_id: legacy_record.id,
            added_at: convert_timestamp_value(legacy_record.time),
            author_email: Legacy::User.generate_dummy_email(legacy_record.user.to_i), # TODO skip emails for now
            # author_email: legacy_record.email, # TODO skip emails for now
            author_name: legacy_record.meno,
            embed: legacy_record.embed.presence,
            image: legacy_record.image.presence,
            ip: legacy_record.ip,
            link: legacy_record.link.presence,
            published: legacy_record.is_published,
            state: legacy_record.status,
            text: legacy_record.komentar,
            verification: legacy_record.verification,
            author: Legacy::User.find_or_create_user(legacy_record.user)
          )
          comment.activity ||= issue.comment_activities.create!
          comment.save!

          import_photos_job.perform_later(comment: comment)
        end
      end
    end
  end
end
