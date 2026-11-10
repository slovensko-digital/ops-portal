require "test_helper"

class Connector::ProcessBackofficeArticleVisibilityJobTest < ActiveJob::TestCase
  def setup
    @tenant = connector_tenants(:default)
    @issue = issues(:two)
    @comment = Issues::ResponsibleSubjectComment.create!(
      text: "Odpoveď zodpovedného subjektu.",
      responsible_subject_author: responsible_subjects(:one),
      triage_external_id: 7,
      activity: Issues::CommentActivity.new(issue: @issue)
    )
    @tenant.activities.create!(backoffice_external_id: 9, triage_external_id: 7)
  end

  def backoffice_article(internal:, created_at: 1.hour.ago, updated_at: Time.current)
    OpenStruct.new(internal: internal, created_at: created_at, updated_at: updated_at)
  end

  def backoffice_client(article, ticket_id: "123", article_id: "9")
    client = Minitest::Mock.new
    client.expect :get_article, article, [ ticket_id, article_id ]
    client
  end

  test "hides the triage article and reverts the issue state when the only visible comment is hidden" do
    triage_client = Minitest::Mock.new
    triage_client.expect :update_article_internal!, nil, [ 7, true ]
    triage_client.expect :update_ticket!, nil, [ 3, { "ops_state" => "sent_to_responsible" } ]

    Connector::ProcessBackofficeArticleVisibilityJob.perform_now(
      @tenant, "123", "9",
      backoffice_client: backoffice_client(backoffice_article(internal: true)),
      triage_client: triage_client
    )

    assert_mock triage_client
  end

  test "hides the triage article but leaves the state alone when another visible comment remains" do
    Issues::ResponsibleSubjectComment.create!(
      text: "Ďalšia odpoveď zodpovedného subjektu.",
      responsible_subject_author: responsible_subjects(:one),
      triage_external_id: 8,
      activity: Issues::CommentActivity.new(issue: @issue)
    )

    triage_client = Minitest::Mock.new
    triage_client.expect :update_article_internal!, nil, [ 7, true ]

    Connector::ProcessBackofficeArticleVisibilityJob.perform_now(
      @tenant, "123", "9",
      backoffice_client: backoffice_client(backoffice_article(internal: true)),
      triage_client: triage_client
    )

    assert_mock triage_client
  end

  test "shows the triage article and advances the issue state when an internal comment becomes public" do
    @issue.update!(state: issues_states(:sent_to_responsible))

    triage_client = Minitest::Mock.new
    triage_client.expect :update_article_internal!, nil, [ 7, false ]
    triage_client.expect :update_ticket!, nil, [ 3, { "ops_state" => "in_progress" } ]

    Connector::ProcessBackofficeArticleVisibilityJob.perform_now(
      @tenant, "123", "9",
      backoffice_client: backoffice_client(backoffice_article(internal: false)),
      triage_client: triage_client
    )

    assert_mock triage_client
  end

  test "forwards an internal comment that has never reached triage when it becomes public" do
    # internal articles created in backoffice have no activity mapping yet
    @tenant.activities.find_by(backoffice_external_id: 9).destroy!
    @tenant.issues.create!(backoffice_external_id: 123)

    assert_enqueued_with(job: Connector::SendNewActivityToTriageFromBackofficeJob, args: [ @tenant, "123", "9" ]) do
      Connector::ProcessBackofficeArticleVisibilityJob.perform_now(
        @tenant, "123", "9",
        backoffice_client: backoffice_client(backoffice_article(internal: false)),
        triage_client: Minitest::Mock.new
      )
    end
  end

  test "processes a visibility change exactly at the 24 hour boundary" do
    created_at = 25.hours.ago
    triage_client = Minitest::Mock.new
    triage_client.expect :update_article_internal!, nil, [ 7, true ]
    triage_client.expect :update_ticket!, nil, [ 3, { "ops_state" => "sent_to_responsible" } ]

    Connector::ProcessBackofficeArticleVisibilityJob.perform_now(
      @tenant, "123", "9",
      backoffice_client: backoffice_client(backoffice_article(internal: true, created_at: created_at, updated_at: created_at + 24.hours)),
      triage_client: triage_client
    )

    assert_mock triage_client
  end

  test "propagates an admin visibility change after the 24 hour window" do
    triage_client = Minitest::Mock.new
    triage_client.expect :update_article_internal!, nil, [ 7, true ]
    triage_client.expect :update_ticket!, nil, [ 3, { "ops_state" => "sent_to_responsible" } ]

    Connector::ProcessBackofficeArticleVisibilityJob.perform_now(
      @tenant, "123", "9", true,
      backoffice_client: backoffice_client(backoffice_article(internal: true, created_at: 25.hours.ago, updated_at: 1.minute.ago)),
      triage_client: triage_client
    )

    assert_mock triage_client
  end

  test "ignores a visibility change after the 24 hour window" do
    triage_client = Minitest::Mock.new

    Connector::ProcessBackofficeArticleVisibilityJob.perform_now(
      @tenant, "123", "9",
      backoffice_client: backoffice_client(backoffice_article(internal: true, created_at: 25.hours.ago, updated_at: 1.minute.ago)),
      triage_client: triage_client
    )

    assert_mock triage_client
  end

  test "ignores an article that no longer exists in backoffice" do
    client = Minitest::Mock.new
    client.expect :get_article, nil, [ "123", "999" ]

    assert_no_enqueued_jobs do
      Connector::ProcessBackofficeArticleVisibilityJob.perform_now(
        @tenant, "123", "999",
        backoffice_client: client,
        triage_client: Minitest::Mock.new
      )
    end

    assert_mock client
  end

  test "ignores a public article on a ticket that does not belong to the tenant" do
    assert_no_enqueued_jobs do
      Connector::ProcessBackofficeArticleVisibilityJob.perform_now(
        @tenant, "123", "999",
        backoffice_client: backoffice_client(backoffice_article(internal: false), article_id: "999"),
        triage_client: Minitest::Mock.new
      )
    end
  end
end
