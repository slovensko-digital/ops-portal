require "test_helper"

module Notifications
  class PublishIssueResponsibleSubjectChangedJobTest < ActiveJob::TestCase
    include ActionMailer::TestHelper

    setup do
      @issue = issues(:one)
      @author_subscription = issue_subscriptions(:one)            # users(:one), author
      @watcher_subscription = issue_subscriptions(:one_two)       # users(:two)
    end

    test "notifies all active subscribers with the previous responsible subject" do
      Notifications::PublishIssueResponsibleSubjectChangedJob.perform_now(
        @issue, responsible_subject_id_change: [ responsible_subjects(:one).id, responsible_subjects(:two).id ]
      )

      assert_enqueued_emails 2
      assert_enqueued_email_with NotificationMailer, :issue_responsible_subject_changed,
        params: { subscription: @author_subscription }, args: [ responsible_subjects(:one) ]
      assert_enqueued_email_with NotificationMailer, :issue_responsible_subject_changed,
        params: { subscription: @watcher_subscription }, args: [ responsible_subjects(:one) ]
    end

    test "notifies without a previous responsible subject when the issue gets its first one" do
      Notifications::PublishIssueResponsibleSubjectChangedJob.perform_now(
        @issue, responsible_subject_id_change: [ nil, responsible_subjects(:two).id ]
      )

      assert_enqueued_emails 2
      assert_enqueued_email_with NotificationMailer, :issue_responsible_subject_changed,
        params: { subscription: @author_subscription }, args: [ nil ]
    end

    test "fails when the previous responsible subject does not exist" do
      assert_raises ActiveRecord::RecordNotFound do
        Notifications::PublishIssueResponsibleSubjectChangedJob.new.perform(
          @issue, responsible_subject_id_change: [ ResponsibleSubject.maximum(:id) + 1, responsible_subjects(:two).id ]
        )
      end

      assert_no_enqueued_emails
    end

    test "nothing happens without a responsible subject change" do
      Notifications::PublishIssueResponsibleSubjectChangedJob.perform_now(@issue, responsible_subject_id_change: [])

      assert_no_enqueued_emails
    end
  end
end
