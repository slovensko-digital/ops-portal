module Notifications
  class PublishIssueAcceptedJob < ApplicationJob
    def perform(issue, notification_mailer: NotificationMailer)
      issue.subscriptions.each do |subscription|
        user = subscription.subscriber
        next unless user.email_notifiable? && user == issue.author

        if issue.issue_type == "praise"
          notification_mailer.with(subscription: subscription).praise_accepted.deliver_later
        else
          notification_mailer.with(subscription: subscription).issue_accepted.deliver_later
        end
      end
    end
  end
end
