module Import
  class Issues::ImportIssueCommentsJob < ApplicationJob
    queue_with_priority 100

    include ImportMethods

    def perform(
      issue:,
      import_photos_job: Issues::ImportIssueCommentAttachmentsJob,
      import_votes_job: Issues::ImportIssueCommentVotesJob
    )
      Legacy::Alerts::Comment.where(remoteid: issue.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          ActiveRecord::Base.transaction do
            comment_type = if Legacy::User.find_or_create_agent(legacy_record.user).present?
              if issue.state.key == "waiting"
               "Issues::AgentPrivateComment"
              else
               "Issues::AgentComment"
              end
            else
              if issue.state.key == "waiting"
                "Issues::UserPrivateComment"
              else
                "Issues::UserComment"
              end
            end

            comment = ::Issues::Comment.find_or_initialize_by(
              legacy_comment_id: legacy_record.id,
              author_email: ENV["EMAILS_IMPORT"] == "ON" ? legacy_record.email : Legacy::User.generate_dummy_email(legacy_record.user),
              author_name: legacy_record.meno,
              hidden: legacy_record.is_published == 0,
              ip: legacy_record.ip,
              text: legacy_record.komentar,
              verification: legacy_record.verification,
              created_at: convert_timestamp_value(legacy_record.time),
              user_author: Legacy::User.find_or_create_user(legacy_record.user),
              agent_author: Legacy::User.find_or_create_agent(legacy_record.user),
              type: comment_type
            )
            comment.imported_at ||= Time.now
            comment.activity ||= issue.comment_activities.create!(created_at: comment.created_at)
            comment.save!

            import_photos_job.set(queue: "import_comment_attachments").perform_later(comment: comment)
            import_votes_job.set(queue: "import_comment_votes").perform_later(comment: comment)
          end
        end
      end
    end
  end
end
