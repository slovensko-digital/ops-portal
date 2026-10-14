require "test_helper"

class SyncIssueActivityObjectToTriageJobTest < ActiveJob::TestCase
  setup do
    @issue = issues(:one)

    activity = Issues::UpdateActivity.create!(issue: @issue)

    @issue_update = Issues::Update.new(
      activity: activity,
      author: @issue.author,
      text: "Vyriešené!",
      resolves_issue: true,
      published: true
    )

    @issue_update.attachments.attach(
      io: File.open(Rails.root.join("test/fixtures/files/graffiti-with-geo.jpg")),
      filename: "graffiti-with-geo.jpg",
      content_type: "image/jpeg"
    )

    @issue_update.save!
  end

  test "creates verification ticket and auto-resolves issue in triage when author marks it resolved" do
    triage_zammad_client_mock = Minitest::Mock.new

    triage_zammad_client_mock.expect :create_ticket_from_issue_update!, 99, [ @issue_update ]

    triage_zammad_client_mock.expect :create_system_note!, nil, [
      @issue.resolution_external_id,
      "Stav podnetu bol zmenený na Vyriešený na základe informácie od zadávateľa podnetu."
    ], **{
      internal: false,
      sender: "Agent"
    }

    triage_zammad_client_mock.expect :update_ticket!, nil, [
      @issue.resolution_external_id,
      { "ops_state" => "resolved", "state" => "closed" }
    ]

    close_job_called = false
    Triage::CloseIssueUpdateTriageTicketJob.stub :perform_now, ->(update, state) {
      close_job_called = true if update == @issue_update && state == "accepted"
    } do
      SyncIssueActivityObjectToTriageJob.new.perform(
        issue: @issue,
        activity_object: @issue_update,
        client: triage_zammad_client_mock
      )
    end

    assert close_job_called
    assert_equal "99", @issue_update.reload.external_id
    assert_mock triage_zammad_client_mock
  end

  test "creates verification ticket but does not auto-resolve issue if author is different" do
    @issue_update.update!(author_id: users(:two).id)

    triage_zammad_client_mock = Minitest::Mock.new
    triage_zammad_client_mock.expect :create_ticket_from_issue_update!, 99, [ @issue_update ]

    SyncIssueActivityObjectToTriageJob.new.perform(
      issue: @issue,
      activity_object: @issue_update,
      client: triage_zammad_client_mock
    )

    assert_equal "99", @issue_update.reload.external_id
    assert_mock triage_zammad_client_mock
  end

  test "creates verification ticket but does not auto-resolve issue if resolves_issue is false" do
    @issue_update.update!(resolves_issue: false)

    triage_zammad_client_mock = Minitest::Mock.new
    triage_zammad_client_mock.expect :create_ticket_from_issue_update!, 99, [ @issue_update ]

    SyncIssueActivityObjectToTriageJob.new.perform(
      issue: @issue,
      activity_object: @issue_update,
      client: triage_zammad_client_mock
    )

    assert_equal "99", @issue_update.reload.external_id
    assert_mock triage_zammad_client_mock
  end

  test "does nothing if issue update already has external_id" do
    @issue_update.update!(external_id: "99", confirmed: false)

    triage_zammad_client_mock = Minitest::Mock.new

    SyncIssueActivityObjectToTriageJob.new.perform(
      issue: @issue,
      activity_object: @issue_update,
      client: triage_zammad_client_mock
    )

    assert_equal "99", @issue_update.reload.external_id
    assert_mock triage_zammad_client_mock
  end

  test "links the existing verification ticket when zammad rejects its number as a duplicate" do
    @issue_update.update!(author_id: users(:two).id)

    existing_ticket = OpenStruct.new(id: 77, number: @issue_update.ticket_number)
    search_queries = []
    search_stub = Object.new
    search_stub.define_singleton_method(:search) { |query:| search_queries << query; [ existing_ticket ] }
    inner_client = Object.new
    inner_client.define_singleton_method(:ticket) { search_stub }

    client_stub = Object.new
    client_stub.define_singleton_method(:create_ticket_from_issue_update!) do |*|
      raise RuntimeError, "Can't save object (ZammadAPI::Resources::Ticket): Error ID UHsZyX7A: Please contact your administrator."
    end
    client_stub.define_singleton_method(:client) { inner_client }
    client_stub.define_singleton_method(:link_tickets!) { |**| }

    SyncIssueActivityObjectToTriageJob.new.perform(
      issue: @issue,
      activity_object: @issue_update,
      client: client_stub
    )

    assert_equal "77", @issue_update.reload.external_id
    assert_equal [ @issue_update.ticket_number ], search_queries
  end
end
