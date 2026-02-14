require "test_helper"

class PublishIssueAcceptedJobTest < ActiveJob::TestCase
  test "praise accepted event: notifies only active subscribers who are the issue author" do
    @issue = issues(:praise_waiting)
    @active_subscription = issue_subscriptions(:praise)
    @inactive_subscription = issue_subscriptions(:praise_legacy_citizen)
    @other_user_subscription = issue_subscriptions(:praise_two)
    @notification_mailer = Minitest::Mock.new

    @notification_mailer.expect :with, @notification_mailer, [], **{ subscription: @active_subscription }
    @notification_mailer.expect :praise_accepted, @notification_mailer, []
    @notification_mailer.expect :deliver_later, nil

    Notifications::PublishIssueAcceptedJob.new.perform(@issue, notification_mailer: @notification_mailer)

    assert_mock @notification_mailer
  end

  test "issue accepted event: notifies only active subscribers who are the issue author" do
    @issue = issues(:one)
    @active_subscription = issue_subscriptions(:one)
    @inactive_subscription = issue_subscriptions(:one_legacy_citizen)
    @other_user_subscription = issue_subscriptions(:one_two)
    @notification_mailer = Minitest::Mock.new

    @notification_mailer.expect :with, @notification_mailer, [], **{ subscription: @active_subscription }
    @notification_mailer.expect :issue_accepted, @notification_mailer, []
    @notification_mailer.expect :deliver_later, nil

    Notifications::PublishIssueAcceptedJob.new.perform(@issue, notification_mailer: @notification_mailer)

    assert_mock @notification_mailer
  end
end
