module Import
  class Issues::FixIssueUpdateConfirmationJob < ApplicationJob
    queue_with_priority 100

    def perform(issue_update)
      legacy_record = Legacy::Alerts::Update.find(issue_update.legacy_id)

      issue_update.confirmed_by = Legacy::User.find_or_create_agent(legacy_record.confirmed_by)
      issue_update.verification_status = "approved" if legacy_record.confirmed_by.to_i > 0
      issue_update.save!
    end
  end
end
