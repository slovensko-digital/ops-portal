module Notifications
  class PublishIssueResponsibleSubjectChangedJob < ApplicationJob
    def perform(issue, responsible_subject_id_change: [], notification_mailer: NotificationMailer)
      return unless responsible_subject_id_change.present?

      previous_rs = ResponsibleSubject.find(responsible_subject_id_change.first)

      issue.subscriptions.active.each do |subscription|
        next unless subscription.subscriber.email_notifiable?

        notification_mailer.with(subscription: subscription).issue_responsible_subject_changed(previous_rs).deliver_later
      end
    end
  end
end
