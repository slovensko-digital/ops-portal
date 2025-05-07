module Import
  class Issues::ImportIssueCommentsJob < ApplicationJob
    include ImportMethods

    def perform(
      issue:,
      import_photos_job: Issues::ImportIssueCommentAttachmentsJob,
      import_votes_job: Issues::ImportIssueCommentVotesJob
    )
      Legacy::Alerts::Comment.where(remoteid: issue.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          comment_type = if Legacy::User.find_or_create_agent(legacy_record.user).present?
           "Issues::AgentComment"
          else
           "Issues::UserComment"
          end

          comment = ::Issues::Comment.find_or_initialize_by(
            legacy_comment_id: legacy_record.id,
            author_email: Legacy::User.generate_dummy_email(legacy_record.user.to_i), # TODO skip emails for now
            # author_email: legacy_record.email, # TODO skip emails for now
            author_name: legacy_record.meno,
            hidden: !legacy_record.is_published,
            ip: legacy_record.ip,
            text: legacy_record.komentar,
            verification: legacy_record.verification,
            created_at: convert_timestamp_value(legacy_record.time),
            user_author: Legacy::User.find_or_create_user(legacy_record.user),
            agent_author: Legacy::User.find_or_create_agent(legacy_record.user),
            type: comment_type
          )
          comment.imported_at ||= Time.now
          comment.activity ||= issue.comment_activities.create!
          comment.save!

          import_photos_job.perform_later(comment: comment)
          import_votes_job.perform_later(comment: comment)
        end
      end
    end
  end
end
