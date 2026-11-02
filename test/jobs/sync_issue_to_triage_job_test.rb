require "test_helper"
require "test_helpers/zammad_helper"

class SyncIssueToTriageJobTest < ActiveJob::TestCase
  include ZammadHelper

  test "creates issue in triage zammad and sets its external ID if not yet created if import mode" do
    issue = issues(:without_triage_external_id)

    triage_zammad_client_mock = Minitest::Mock.new
    triage_zammad_client_mock.expect :check_import_mode!, nil
    triage_zammad_client_mock.expect :get_groups, [
      OpenStruct.new(name: "Dobrovoľníci::Nitra"),
      OpenStruct.new(name: "Dobrovoľníci::Trenčín"),
      OpenStruct.new(name: "Dobrovoľníci::Prešov")
    ]
    triage_zammad_client_mock.expect :create_ticket_from_issue!, 99, [ issue ],
      **{
        issue_number: "T-#{issue.id}",
        process_type: "portal_issue_triage",
        state: "new",
        group: "Dobrovoľníci::Trenčín",
        owner_id: nil
      }

    ZammadApiClient.stub :new, triage_zammad_client_mock do
      SyncIssueToTriageJob.perform_now(issue, client: triage_zammad_client_mock, import: true)
    end

    assert_equal 99, issue.reload.triage_external_id
  end

  test "creates issue in triage zammad and sets its external ID if not yet created" do
    issue = issues(:without_triage_external_id)

    triage_zammad_client_mock = Minitest::Mock.new
    triage_zammad_client_mock.expect :get_groups, [
      OpenStruct.new(name: "Dobrovoľníci::Nitra"),
      OpenStruct.new(name: "Dobrovoľníci::Trenčín"),
      OpenStruct.new(name: "Dobrovoľníci::Prešov")
    ]
    triage_zammad_client_mock.expect :create_ticket_from_issue!, 99, [ issue ],
    **{
      issue_number: "T-#{issue.id}"
    }

    ZammadApiClient.stub :new, triage_zammad_client_mock do
      SyncIssueToTriageJob.perform_now(issue, client: triage_zammad_client_mock)
    end

    assert_equal 99, issue.reload.triage_external_id
  end

  test "creates issue with its author in triage zammad and sets external IDs if not yet created if import mode" do
    issue = issues(:without_triage_external_id)
    issue.update!(author: users(:two))

    triage_zammad_client_mock = Minitest::Mock.new
    triage_zammad_client_mock.expect :check_import_mode!, nil
    triage_zammad_client_mock.expect :get_groups, [
      OpenStruct.new(name: "Dobrovoľníci::Nitra"),
      OpenStruct.new(name: "Dobrovoľníci::Trenčín"),
      OpenStruct.new(name: "Dobrovoľníci::Prešov")
    ]
    triage_zammad_client_mock.expect :create_customer!, 9, [ issue.author ]
    triage_zammad_client_mock.expect :create_ticket_from_issue!, 99, [ issue ],
      **{
        issue_number: "T-#{issue.id}",
        process_type: "portal_issue_triage",
        state: "new",
        group: "Dobrovoľníci::Trenčín",
        owner_id: nil
      }

    ZammadApiClient.stub :new, triage_zammad_client_mock do
      SyncIssueToTriageJob.perform_now(issue, client: triage_zammad_client_mock, import: true)
    end

    assert_equal 9, issue.author.reload.external_id
    assert_equal 99, issue.reload.triage_external_id
  end

  test "creates issue with its author in triage zammad and sets external IDs if not yet created" do
    issue = issues(:without_triage_external_id)
    issue.update!(author: users(:two))

    triage_zammad_client_mock = Minitest::Mock.new
    triage_zammad_client_mock.expect :get_groups, [
      OpenStruct.new(name: "Dobrovoľníci::Nitra"),
      OpenStruct.new(name: "Dobrovoľníci::Trenčín"),
      OpenStruct.new(name: "Dobrovoľníci::Prešov")
    ]
    triage_zammad_client_mock.expect :create_customer!, 9, [ issue.author ]
    triage_zammad_client_mock.expect :create_ticket_from_issue!, 99, [ issue ],
    **{
      issue_number: "T-#{issue.id}"
    }

    ZammadApiClient.stub :new, triage_zammad_client_mock do
      SyncIssueToTriageJob.perform_now(issue, client: triage_zammad_client_mock)
    end

    assert_equal 9, issue.author.reload.external_id
    assert_equal 99, issue.reload.triage_external_id
  end

  test "creates issue with its owner in triage zammad and sets external IDs if not yet created if import mode" do
    issue = issues(:without_triage_external_id)
    issue.update!(owner: legacy_agents(:two))

    triage_zammad_client_mock = Minitest::Mock.new
    triage_zammad_client_mock.expect :check_import_mode!, nil
    triage_zammad_client_mock.expect :get_groups, [
      OpenStruct.new(name: "Dobrovoľníci::Nitra"),
      OpenStruct.new(name: "Dobrovoľníci::Trenčín"),
      OpenStruct.new(name: "Dobrovoľníci::Prešov")
    ]
    triage_zammad_client_mock.expect :create_agent!, 9, [ issue.owner ]
    triage_zammad_client_mock.expect :add_user_to_group, nil, [ 9, "Dobrovoľníci::Trenčín" ]
    triage_zammad_client_mock.expect :create_ticket_from_issue!, 99, [ issue ],
      **{
        issue_number: "T-#{issue.id}",
        process_type: "portal_issue_triage",
        state: "new",
        group: "Dobrovoľníci::Trenčín",
        owner_id: 9
      }

    ZammadApiClient.stub :new, triage_zammad_client_mock do
      SyncIssueToTriageJob.perform_now(issue, client: triage_zammad_client_mock, import: true)
    end

    assert_equal 9, issue.owner.reload.external_id
    assert_equal 99, issue.reload.triage_external_id
  end

  test "updates existing issue in resolution process attributes" do
    issue = issues(:one)
    issue_last_synced_at = issue.last_synced_at

    triage_zammad_client_mock = Minitest::Mock.new
    triage_zammad_client_mock.expect :get_groups, [
      OpenStruct.new(name: "Dobrovoľníci::Nitra"),
      OpenStruct.new(name: "Dobrovoľníci::Trenčín"),
      OpenStruct.new(name: "Dobrovoľníci::Prešov"),
      OpenStruct.new(name: "Dobrovoľníci::Bratislava")
    ]
    triage_zammad_client_mock.expect :update_ticket_from_issue!, nil, [ issue.resolution_external_id, issue ]

    ZammadApiClient.stub :new, triage_zammad_client_mock do
      SyncIssueToTriageJob.perform_now(issue, client: triage_zammad_client_mock)
    end

    assert_not_equal issue_last_synced_at, issue.last_synced_at
  end

  test "import fails if zammad not in import mode" do
    issue = issues(:without_triage_external_id)

    triage_zammad_client_mock = Minitest::Mock.new
    triage_zammad_client_mock.expect :check_import_mode!, StandardError.new("Import mode OFF")

    ZammadApiClient.stub :new, triage_zammad_client_mock do
      assert_raise do
        SyncIssueToTriageJob.perform_now(issue, client: triage_zammad_client_mock)
      end
    end

    assert_nil issue.triage_external_id
  end

  test "links the existing ticket when triage zammad rejects its number as a duplicate" do
    issue = issues(:without_triage_external_id)
    issue_number = "T-#{issue.id.to_s.rjust(4, '0')}"
    client = ZammadApiClient.new(url: ENV.fetch("TRIAGE_ZAMMAD_URL"), http_token: "token")

    # what Zammad 7.2 answers when the ticket number already exists
    stub_zammad(:post, "tickets", status: 422, body: { error: "Error ID UHsZyX7A: Please contact your administrator." })
    stub_zammad(:get, "tickets/search", body: [
      zammad_fixture("zammad/ticket_resolution", id: 77, number: "#{issue_number}1"),
      zammad_fixture("zammad/ticket_resolution", id: 78, number: issue_number)
    ])

    SyncIssueToTriageJob.new.perform(issue, client: client)

    assert_equal 78, issue.reload.triage_external_id
    assert_requested :get, zammad_url("tickets/search"), query: hash_including("query" => issue_number)
  end
end
