require "test_helper"

module Notifications
  class PublishIssueStateChangedJobTest < ActiveJob::TestCase
    test "only active subscribers get notified when issue is resolved" do
      @issue = issues(:one)
      @active_subscription = issue_subscriptions(:one)
      @inactive_subscription = issue_subscriptions(:one_legacy_citizen)
      @another_active_subscription = issue_subscriptions(:one_two)
      @notification_mailer = Minitest::Mock.new

      @notification_mailer.expect :with, @notification_mailer, [], **{ subscription: @active_subscription }
      @notification_mailer.expect :issue_resolved, @notification_mailer, []
      @notification_mailer.expect :deliver_later, nil

      @notification_mailer.expect :with, @notification_mailer, [], **{ subscription: @another_active_subscription }
      @notification_mailer.expect :issue_resolved, @notification_mailer, []
      @notification_mailer.expect :deliver_later, nil

      state_id_change = [ Issues::State.find_by(key: "waiting").id, Issues::State.find_by(key: "resolved").id ]
      Notifications::PublishIssueStateChangedJob.new.perform(@issue, state_id_change: state_id_change, notification_mailer: @notification_mailer)

      assert_mock @notification_mailer
    end
  end
end
