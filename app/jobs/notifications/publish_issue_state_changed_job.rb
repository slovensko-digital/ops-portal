module Notifications
  class PublishIssueStateChangedJob < ApplicationJob
    def perform(issue, state_id_change: [], notification_mailer: NotificationMailer)
      return unless state_id_change.present?

      issue.subscriptions.each do |subscription|
        next unless subscription.subscriber.email_notifiable?

        case Issue::State.find(state_id_change.last).key
        when "rejected"
          next unless issue.author == subscription.subscriber
          notification_mailer.with(subscription: subscription).issue_rejected(issue).deliver_later
        when "resolved"
          notification_mailer.with(subscription: subscription).issue_resolved(issue).deliver_later
        when "unresolved"
          notification_mailer.with(subscription: subscription).issue_unresolved(issue).deliver_later
        when "referred"
          notification_mailer.with(subscription: subscription).issue_referred(issue).deliver_later
        when "closed"
          notification_mailer.with(subscription: subscription).issue_closed(issue).deliver_later
        end
      end
    end
  end
end
