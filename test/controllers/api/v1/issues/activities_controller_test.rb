require "test_helper"
require "test_helpers/api_helper"
require "test_helpers/triage_helper"
require "test_helpers/zammad_helper"

class Api::V1::Issues::ActivitiesControllerTest < ActionDispatch::IntegrationTest
  include ApiHelper
  include TriageHelper
  include ZammadHelper

  ACTIVITY_SCHEMA = {
    triage_identifier: Integer, activity_type: String, uuid: String, author: [ Hash, NilClass ], content_type: String, body: String,
    created_at: String, updated_at: String,
    attachments: [ { triage_identifier: Integer, filename: String, content_type: String, data64: String } ]
  }.freeze

  ACTIVITY_WITH_URLS_SCHEMA = ACTIVITY_SCHEMA.merge(
    attachments: [ { triage_identifier: Integer, filename: String, content_type: String, url: String } ]
  ).freeze

  setup do
    @client, @key = api_client_with_key
    @responsible_subject = @client.responsible_subject
    @token = api_token(@client, @key)
    @issue = issues(:sent_to_responsible)
    @issue.update_columns(responsible_subject_id: @responsible_subject.id)
    @ticket = triage_ticket(@issue)
  end

  test "show returns an activity of the issue" do
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, @ticket, [ "601" ], download_attachments: false
    article = triage_article(article_type: :agent_backoffice_comment, body: "Odpoveď", attachments: [ triage_attachment ])
    zammad.expect :get_article, article, [ "601", "7" ], responsible_subject: @responsible_subject, download_attachments: true

    with_zammad_client(zammad) do
      get api_v1_issue_activity_url(601, 7), headers: api_headers(@token)
    end

    assert_response :success
    assert_mock zammad
    assert_json_schema ACTIVITY_SCHEMA, response.parsed_body
    assert_equal "agent_backoffice_comment", response.parsed_body["activity_type"]
    assert_equal "Odpoveď", response.parsed_body["body"]
    assert_equal article[:uuid], response.parsed_body["uuid"]
  end

  test "show with attachment_urls links attachments instead of embedding them" do
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, @ticket, [ "601" ], download_attachments: false
    article = triage_article(article_type: :agent_backoffice_comment, body: "Odpoveď", attachments: [ triage_attachment.except(:data64) ])
    zammad.expect :get_article, article, [ "601", "7" ], responsible_subject: @responsible_subject, download_attachments: false

    with_zammad_client(zammad) do
      get api_v1_issue_activity_url(601, 7, attachment_urls: "true"), headers: api_headers(@token)
    end

    assert_response :success
    assert_mock zammad
    assert_json_schema ACTIVITY_WITH_URLS_SCHEMA, response.parsed_body
    assert_match %r{/api/v1/issues/601/activities/1/attachments/1\?expires=\d+&signature=\h{64}\z}, response.parsed_body.dig("attachments", 0, "url")
  end

  # a praise in triage, served through the real client: its first article has attachments 501 and 502
  def with_triage_praise(&block)
    stub_zammad(:get, "tickets/42", fixture: "zammad/ticket_resolution", overrides: {
      issue_type: "praise", responsible_subject: { label: @responsible_subject.subject_name, value: @responsible_subject.id }
    })
    stub_zammad(:get, "ticket_articles/by_ticket/42", body: zammad_fixture("zammad/ticket_articles"))
    stub_zammad(:get, "users/1", fixture: "zammad/user_portal")
    with_zammad_client(ZammadApiClient.new(url: ENV.fetch("TRIAGE_ZAMMAD_URL"), http_token: "token"), &block)
  end

  test "show with attachment_urls does not download the attachments of a praise" do
    with_triage_praise do
      get api_v1_issue_activity_url(42, 101, attachment_urls: "true"), headers: api_headers(@token)
    end

    assert_response :success
    assert_equal [ 501 ], response.parsed_body["attachments"].map { it["triage_identifier"] }
    assert_not_requested :get, %r{ticket_attachment/}
  end

  test "show of an activity the responsible subject may not see is not found" do
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, @ticket, [ "601" ], download_attachments: false
    zammad.expect :get_article, nil, [ "601", "7" ], responsible_subject: @responsible_subject, download_attachments: true

    with_zammad_client(zammad) do
      get api_v1_issue_activity_url(601, 7), headers: api_headers(@token)
    end

    assert_response :not_found
  end

  test "create adds an article to the triage ticket and returns its id" do
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, @ticket, [ "601" ], download_attachments: false
    zammad.expect :create_article_from_api!, 99, [ @responsible_subject.external_id, "601", ActionController::Parameters ]

    with_zammad_client(zammad) do
      post api_v1_issue_activities_url(601),
        params: { activity: { content_type: "text/plain", body: "Riešime", attachments: [ { filename: "a.jpg", content_type: "image/jpeg", data64: "AAAA" } ] } }.to_json,
        headers: api_headers(@token).merge("Content-Type" => "application/json")
    end

    assert_response :success
    assert_mock zammad
    assert_equal({ "activity_id" => 99 }, response.parsed_body)
  end

  test "create registers the responsible subject in triage first when it has no external id" do
    @responsible_subject.update_columns(external_id: nil)
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, @ticket, [ "601" ], download_attachments: false
    zammad.expect :create_responsible_subject!, "5555", [ @responsible_subject ]
    zammad.expect :create_article_from_api!, 100, [ "5555", "601", ActionController::Parameters ]

    with_zammad_client(zammad) do
      post api_v1_issue_activities_url(601), params: { activity: { content_type: "text/plain", body: "Riešime" } }, headers: api_headers(@token)
    end

    assert_response :success
    assert_mock zammad
    assert_equal "5555", @responsible_subject.reload.external_id
  end

  test "create on a ticket of another responsible subject is not found" do
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, triage_ticket(issues(:legacy1)), [ "3" ], download_attachments: false

    with_zammad_client(zammad) do
      post api_v1_issue_activities_url(3), params: { activity: { body: "x" } }, headers: api_headers(@token)
    end

    assert_response :not_found
  end

  test "requests without token are rejected" do
    get api_v1_issue_activity_url(601, 7)
    assert_response :bad_request
  end
end
