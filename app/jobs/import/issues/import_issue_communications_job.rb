module Import
  class Issues::ImportIssueCommunicationsJob < ApplicationJob
    queue_with_priority 100

    include ImportMethods

    def perform(
      issue:,
      import_attachments_job: Issues::ImportIssueCommunicationAttachmentsJob,
      import_votes_job: Issues::ImportIssueCommunicationVotesJob
    )
      # !! DO NOT ever delete the internal attribute condition !!
      Legacy::Alerts::Communication.where(alert: issue.legacy_id).where(internal: 0).find_in_batches do |group|
        group.each do |legacy_record|
          ActiveRecord::Base.transaction do
            if legacy_record.direction == true
              communication = ::Issues::ResponsibleSubjectComment.find_or_initialize_by(
                legacy_communication_id: legacy_record.id,
                author_email: ENV["EMAILS_IMPORT"] == "ON"  ? legacy_record.email : Legacy::User.generate_dummy_email(legacy_record.user),
                author_name: legacy_record.signature,
                hidden: legacy_record.internal,
                ip: legacy_record.ip,
                legacy_data: {
                  confirmation_needed: legacy_record.need_confirmation,
                  direction: legacy_record.direction,
                  plain_message: legacy_record.plain_message,
                  signature: legacy_record.signature,
                  solution_rejected: legacy_record.solution_rejected,
                  solved: legacy_record.solution_done,
                  solved_by: legacy_record.solution_who,
                  solved_in: legacy_record.solution_when,
                  subject: legacy_record.subject,
                  text: legacy_record.text,
                  admin_id: legacy_record.admin,
                  person_id: legacy_record.person,
                  user_id: legacy_record.user # legacy_id of ResponsibleSubject::User author
                },
                text: legacy_record.message,
                created_at: convert_timestamp_value(legacy_record.ts),
                responsible_subject_author: Legacy::User.find_or_create_responsible_subjects_user(legacy_record.user)&.responsible_subject,
              )
              communication.activity ||= issue.comment_activities.create!(created_at: communication.created_at)

            else
              communication_type = if legacy_record.user.nil? || legacy_record.user == 0
                "Legacy::Issues::AgentInternalCommunication"
              else
                "Legacy::Issues::ResponsibleSubjectInternalCommunication"
              end

              communication = ::Legacy::Issues::Communication.find_or_initialize_by(
                legacy_id: legacy_record.id,
                agent_author: Legacy::User.find_or_create_agent(legacy_record.admin),
                responsible_subjects_user_author: Legacy::User.find_or_create_responsible_subjects_user(legacy_record.user),
                confirmation_needed: legacy_record.need_confirmation,
                email: ENV["EMAILS_IMPORT"] == "ON" ? legacy_record.email : Legacy::User.generate_dummy_email(legacy_record.user),
                from_responsible_subject: legacy_record.direction,
                internal: legacy_record.internal,
                ip: legacy_record.ip,
                message: legacy_record.message,
                plain_message: legacy_record.plain_message,
                signature: legacy_record.signature,
                solution_rejected: legacy_record.solution_rejected,
                solved: legacy_record.solution_done,
                solved_by: legacy_record.solution_who,
                solved_in: legacy_record.solution_when,
                subject: legacy_record.subject,
                text: legacy_record.text,
                created_at: convert_timestamp_value(legacy_record.ts),
                admin_id: legacy_record.admin,
                person_id: legacy_record.person,
                user_id: legacy_record.user,
                type: communication_type
              )
              communication.activity ||= issue.legacy_communication_activities.create!(created_at: communication.created_at)
            end
            communication.imported_at ||= Time.now
            communication.save!

            import_attachments_job.perform_later(communication: communication)
            import_votes_job.perform_later(communication: communication)
          end
        end
      end

      update_issue_state(issue)
    end

    private

    def update_issue_state(issue)
      return if issue.state&.key != "in_progress"
      return if issue.comments.where(type: "Issues::ResponsibleSubjectComment").any?

      issue.update(state: ::Issues::State.find_by(key: "sent_to_responsible"))
    end
  end
end
