require "test_helper"
require "test_helpers/triage_helper"

class Triage::UpdatePortalActivityFromTriageJobTest < ActiveJob::TestCase
  include TriageHelper

  setup do
    @comment = issues_comments(:two_comment1)
    @comment.update_columns(triage_external_id: 7, text: "Komentár")
  end

  test "hides the comment when the article became internal" do
    client = Minitest::Mock.new
    client.expect :find_article, [ Object.new, OpenStruct.new(internal: true) ], [ 3, "7" ]

    Triage::UpdatePortalActivityFromTriageJob.new.perform(3, "7", triage_zammad_client: client)

    assert_mock client
    assert @comment.reload.hidden
  end

  test "shows the comment again when the article became public" do
    @comment.update_columns(hidden: true)
    client = Minitest::Mock.new
    client.expect :find_article, [ Object.new, OpenStruct.new(internal: false) ], [ 3, "7" ]

    Triage::UpdatePortalActivityFromTriageJob.new.perform(3, "7", triage_zammad_client: client)

    assert_not @comment.reload.hidden
  end

  test "missing article leaves the comment alone" do
    client = Minitest::Mock.new
    client.expect :find_article, nil, [ 3, "7" ]

    Triage::UpdatePortalActivityFromTriageJob.new.perform(3, "7", triage_zammad_client: client)

    assert_not @comment.reload.hidden
  end

  test "unknown article is imported as a new activity" do
    client = Minitest::Mock.new
    client.expect :get_ticket, triage_ticket(issues(:two)), [ 3 ]
    client.expect :get_article, triage_article(article_type: :agent_portal_comment, body: "Nový článok"), [ 3, "8" ], allowed_article_types: Array

    assert_difference -> { issues(:two).comments.count }, 1 do
      Triage::UpdatePortalActivityFromTriageJob.new.perform(3, "8", triage_zammad_client: client)
    end

    assert_mock client
  end

  test "a failing import of an unknown article fails with its own error" do
    # a plain object like ZammadApiClient, which ActiveJob can't serialize
    client = Object.new
    def client.get_ticket(_ticket_id) = nil

    error = assert_raises(RuntimeError) do
      Triage::UpdatePortalActivityFromTriageJob.new.perform(3, "8", triage_zammad_client: client)
    end

    assert_equal "Ticket not found", error.message
    assert_no_enqueued_jobs
  end
end
