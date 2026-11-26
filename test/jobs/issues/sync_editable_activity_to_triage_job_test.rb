require "test_helper"
require "test_helpers/request_helper"

class Issues::SyncEditableActivityToTriageJobTest < ActiveJob::TestCase
  include RequestHelper

  setup do
    @comment = issues_comments(:one_comment2)
    @comment.update!(hidden: false, ai_evaluation: {})

    @gemini_url = /generativelanguage\.googleapis\.com\/v1beta\/models\/gemini.*:generateContent/
  end

  test "waits for the editing window to close before moderating and syncing" do
    travel_to @comment.created_at do
      assert_enqueued_with(job: Issues::SyncEditableActivityToTriageJob, at: @comment.editing_window_end) do
        Issues::SyncEditableActivityToTriageJob.perform_now(@comment, sync_job: SyncIssueActivityObjectToTriageJob)
      end
    end

    assert_not_requested :post, @gemini_url
    assert_no_enqueued_jobs only: SyncIssueActivityObjectToTriageJob
  end

  test "moderates the comment before enqueuing the triage sync" do
    stub_json_request(:post, @gemini_url, response: "webmock/gemini/moderate-comment-toxic.json")

    travel_to @comment.editing_window_end + 1.second do
      assert_enqueued_with(job: SyncIssueActivityObjectToTriageJob, args: [ { issue: @comment.issue, activity_object: @comment } ]) do
        Issues::SyncEditableActivityToTriageJob.perform_now(@comment, sync_job: SyncIssueActivityObjectToTriageJob)
      end
    end

    assert @comment.reload.hidden?
  end

  test "enqueues the triage sync even when moderation fails" do
    stub_request(:post, @gemini_url).to_timeout

    travel_to @comment.editing_window_end + 1.second do
      assert_enqueued_with(job: SyncIssueActivityObjectToTriageJob) do
        Issues::SyncEditableActivityToTriageJob.perform_now(@comment, sync_job: SyncIssueActivityObjectToTriageJob)
      end
    end

    assert_not @comment.reload.hidden?
    assert_no_enqueued_jobs only: Issues::ModerateCommentJob
  end
end
