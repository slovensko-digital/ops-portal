module Notifications
  class PublishIssueAcceptedJob < ApplicationJob
    def perform(issue, notification_mailer: NotificationMailer)
      issue.subscriptions.each do |subscription|
        user = subscription.subscriber
        next unless user.email_notifiable?

        notification_mailer.with(subscription: subscription).issue_accepted(issue).deliver_later if user == issue.author
      end
    end
  end
end
