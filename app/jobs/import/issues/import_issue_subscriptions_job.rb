module Import
  class Issues::ImportIssueSubscriptionsJob < ApplicationJob
    include ImportMethods

    def perform(issue:)
      Legacy::Alerts::UsersFavorite.where(submission_id: issue.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          user = Legacy::User.find_or_create_user(legacy_record.user_id)

          user.issue_subscriptions.find_or_create_by!(
            issue: issue,
            created_at: legacy_record.created_at
          ) if user
        end
      end
    end
  end
end
