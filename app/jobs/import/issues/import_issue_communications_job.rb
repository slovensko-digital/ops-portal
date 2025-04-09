module Import
  class Issues::ImportIssueCommunicationsJob < ApplicationJob
    include ImportMethods

    def perform(issue:, import_attachments_job: Issues::ImportIssueCommunicationAttachmentsJob)
      Legacy::GenericModel.set_table_name("communication")
      # !! DO NOT ever delete the internal attribute condition !!
      Legacy::GenericModel.where(alert: issue.legacy_id).where(internal: 0).find_in_batches do |group|
        group.each do |legacy_record|
          communication_author = if legacy_record.user.to_i.nonzero?
           ::ResponsibleSubjects::User.find_by(legacy_id: legacy_record.user)
          elsif legacy_record.admin.to_i.nonzero?
            ::Legacy::Agent.find_by(legacy_id: legacy_record.admin)
          end

          communication = ::Issues::Communication.find_or_initialize_by(
            legacy_id: legacy_record.id,
            author: communication_author,
            added_at: convert_timestamp_value(legacy_record.ts),
            confirmation_needed: legacy_record.need_confirmation,
            email: Legacy::User.generate_dummy_email(legacy_record.user), # TODO skip emails for now
            # email: legacy_record.email, # TODO skip emails for now
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
            admin_id: legacy_record.admin,
            person_id: legacy_record.person,
            user_id: legacy_record.user
          )
          communication.activity ||= issue.communication_activities.create!
          communication.save!

          import_attachments_job.perform_later(communication: communication)
        end
      end
    end
  end
end
