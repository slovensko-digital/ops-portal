require "test_helper"

class Notifications::PublishNewIssueCommentJobTest < ActiveJob::TestCase
  setup do
    @comment = issues_comments(:one_comment1)
    @issue = @comment.issue
    @active_subscription = issue_subscriptions(:one)
    @inactive_subscription = issue_subscriptions(:one_legacy_citizen)
    @another_active_subscription = issue_subscriptions(:one_two)
    @notification_mailer = Minitest::Mock.new
  end

  test "sends notifications only to active subscribers (except comment author)" do
    @active_subscription.subscriber.update(email_notifiable: true)
    @inactive_subscription.subscriber.update(email_notifiable: true)
    @another_active_subscription.subscriber.update(email_notifiable: true)

    @notification_mailer.expect(:with, @notification_mailer, [], **{ subscription: @another_active_subscription })
    @notification_mailer.expect(:new_issue_user_comment, @notification_mailer, [ @comment ])
    @notification_mailer.expect(:deliver_later, nil)

    Notifications::PublishNewIssueCommentJob.new.perform(@comment, notification_mailer: @notification_mailer)

    assert_mock @notification_mailer
  end

  test "does not send notifications to users who are not email notifiable" do
    @active_subscription.subscriber.update(email_notifiable: false)
    @another_active_subscription.subscriber.update(email_notifiable: false)

    Notifications::PublishNewIssueCommentJob.new.perform(@comment, notification_mailer: @notification_mailer)

    assert_mock @notification_mailer
  end
end
