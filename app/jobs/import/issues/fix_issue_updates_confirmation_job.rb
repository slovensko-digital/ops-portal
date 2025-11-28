module Import
  class Issues::FixIssueUpdatesConfirmationJob < ApplicationJob
    queue_with_priority 100

    def perform
      ::Issues::Update.where.not(legacy_id: nil).find_in_batches do |group|
        group.each do |issue_update|
          Issues::FixIssueUpdateConfirmationJob.perform_later(issue_update)
        end
      end
    end
  end
end
