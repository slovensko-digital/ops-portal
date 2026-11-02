require "test_helper"

class ApplicationJobTest < ActiveJob::TestCase
  class FailingJob < ApplicationJob
    def perform(_arg)
      raise ArgumentError, "boom"
    end
  end

  class DiscardedJob < ApplicationJob
    discard_on ArgumentError

    def perform(_arg)
      raise ArgumentError, "boom"
    end
  end

  test "reports the error to Rollbar once retries run out" do
    reports = []
    Rollbar.stub(:error, ->(error, data) { reports << [ error, data ] }) do
      FailingJob.perform_later("x")
      4.times { perform_enqueued_jobs(only: FailingJob) }
      assert_empty reports

      assert_raises(ArgumentError) { perform_enqueued_jobs(only: FailingJob) }
    end

    assert_equal 1, reports.size
    error, data = reports.first
    assert_equal "boom", error.message
    assert_equal "ApplicationJobTest::FailingJob", data[:job]
    assert_equal 5, data[:executions]
    assert_equal [ "x" ], data[:arguments]
  end

  test "reports the error to Rollbar when discard_on drops the job" do
    reports = []
    Rollbar.stub(:error, ->(error, data) { reports << [ error, data ] }) do
      DiscardedJob.perform_now("x")
    end

    assert_equal 1, reports.size
    assert_equal "ApplicationJobTest::DiscardedJob", reports.first.last[:job]
  end
end
