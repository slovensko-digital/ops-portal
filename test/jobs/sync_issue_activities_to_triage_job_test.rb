require "test_helper"

class SyncIssueActivitiesToTriageJobTest < ActiveJob::TestCase
  test "a failing activity sync fails the job and the remaining activities are not synced" do
    issue = issues(:one)
    synced = []
    sync_job = Class.new(ApplicationJob) do
      define_method(:perform) do |activity_object:, **|
        synced << activity_object
        raise "Triage unavailable"
      end
    end

    error = assert_raises(RuntimeError) do
      SyncIssueActivitiesToTriageJob.new.perform(issue, triage_group: nil, sync_activity_object_job: sync_job)
    end

    assert_equal "Triage unavailable", error.message
    assert_equal 1, synced.size
    assert_no_enqueued_jobs
  end
end
