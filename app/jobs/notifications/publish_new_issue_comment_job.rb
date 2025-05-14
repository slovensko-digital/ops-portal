module Notifications
  class PublishNewIssueCommentJob < ApplicationJob
    def perform(comment, notification_mailer: NotificationMailer)
      issue = comment.issue
      return if issue.issue_type == "praise"

      issue.subscriptions.each do |subscription|
        user = subscription.subscriber
        next unless user.email_notifiable?
        next if comment.user_author == user

        case comment
        when Issues::UserComment, Issues::AgentComment, Issues::AgentPrivateComment
          notification_mailer.with(subscription: subscription).new_issue_user_comment(comment).deliver_later
        when Issues::ResponsibleSubjectComment
          notification_mailer.with(subscription: subscription).new_issue_responsible_subject_comment(comment).deliver_later
        end
      end
    end
  end
end
