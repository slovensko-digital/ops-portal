module Import
  class Issues::ImportIssueUpdatesJob < ApplicationJob
    queue_with_priority 100

    include ImportMethods

    def perform(issue:, import_photos_job: Issues::ImportIssueUpdateAttachmentsJob)
      Legacy::Alerts::Update.where(alert: issue.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          ActiveRecord::Base.transaction do
            update = ::Issues::Update.find_or_initialize_by(
              legacy_id: legacy_record.id,
              email: Legacy::User.generate_dummy_email(legacy_record.updated_by), # TODO skip emails for now
              # email: legacy_record.email, # TODO skip emails for now
              ip: legacy_record.ip,
              name: legacy_record.meno,
              published: legacy_record.status,
              text: legacy_record.text,
              created_at: convert_timestamp_value(legacy_record.ts),
              author: Legacy::User.find_or_create_user(legacy_record.updated_by),
              confirmed_by: Legacy::User.find_or_create_user(legacy_record.confirmed_by)
            )
            update.imported_at ||= Time.now
            update.activity ||= issue.update_activities.create!(created_at: update.created_at)
            update.save!

            import_photos_job.perform_later(update: update)
          end
        end
      end
    end
  end
end
