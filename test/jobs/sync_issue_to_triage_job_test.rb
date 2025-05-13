require "test_helper"

class SyncIssueToTriageJobTest < ActiveJob::TestCase
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
    triage_zammad_client_mock.expect :create_ticket_from_issue!, 99, [ issue ]

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
    triage_zammad_client_mock.expect :create_ticket_from_issue!, 99, [ issue ]

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

  test "updates existing issue attributes" do
    issue = issues(:one)
    issue_last_synced_at = issue.last_synced_at

    triage_zammad_client_mock = Minitest::Mock.new
    triage_zammad_client_mock.expect :get_groups, [
      OpenStruct.new(name: "Dobrovoľníci::Nitra"),
      OpenStruct.new(name: "Dobrovoľníci::Trenčín"),
      OpenStruct.new(name: "Dobrovoľníci::Prešov"),
      OpenStruct.new(name: "Dobrovoľníci::Bratislava")
    ]
    triage_zammad_client_mock.expect :update_ticket_from_issue!, nil, [ issue.triage_external_id, issue ], update_attachments: true

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
end
