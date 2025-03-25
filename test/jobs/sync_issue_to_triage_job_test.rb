require "test_helper"

class SyncIssueToTriageJobTest < ActiveJob::TestCase
  test "creates issue in triage zammad and sets its external ID" do
    issue = issues(:without_triage_external_id)

    triage_zammad_client_mock = Minitest::Mock.new
    triage_zammad_client_mock.expect :create_ticket!, 99, [ issue ],
      **{
        issue_type: "issue",
        process_type: "portal_issue_triage",
        title: "Triáž: New issue",
        description: "New issue description",
        responsible_subject: nil,
        likes_count: 999
      }

    ZammadApiClient.stub :new, triage_zammad_client_mock do
      SyncIssueToTriageJob.perform_now(issue, client: triage_zammad_client_mock)
    end

    assert_equal 99, issue.reload.triage_external_id
  end

  test "creates issue with its author in triage zammad and sets external IDs" do
    issue = issues(:without_triage_external_id)
    issue.update!(author: users(:two))

    triage_zammad_client_mock = Minitest::Mock.new
    triage_zammad_client_mock.expect :create_customer!, 9, [ issue.author ]
    triage_zammad_client_mock.expect :create_ticket!, 99, [ issue ],
      **{
        issue_type: "issue",
        process_type: "portal_issue_triage",
        title: "Triáž: New issue",
        description: "New issue description",
        responsible_subject: nil,
        likes_count: 999
      }

    ZammadApiClient.stub :new, triage_zammad_client_mock do
      SyncIssueToTriageJob.perform_now(issue, client: triage_zammad_client_mock)
    end

    assert_equal 9, issue.author.reload.zammad_identifier
    assert_equal 99, issue.reload.triage_external_id
  end

  test "creates issue with its owner in triage zammad and sets external IDs" do
    issue = issues(:without_triage_external_id)
    issue.update!(owner: legacy_agents(:two))

    triage_zammad_client_mock = Minitest::Mock.new
    triage_zammad_client_mock.expect :create_agent!, 9, [ issue.owner ]
    triage_zammad_client_mock.expect :get_groups, [
      OpenStruct.new(name: "Dobrovoľníci::Nitra"),
      OpenStruct.new(name: "Dobrovoľníci::Trenčín"),
      OpenStruct.new(name: "Dobrovoľníci::Prešov")
    ]
    triage_zammad_client_mock.expect :add_user_to_group, nil, [ 9, "Dobrovoľníci::Trenčín" ]
    triage_zammad_client_mock.expect :create_ticket!, 99, [ issue ],
      **{
        issue_type: "issue",
        process_type: "portal_issue_triage",
        title: "Triáž: New issue",
        description: "New issue description",
        responsible_subject: nil,
        likes_count: 999
      }

    ZammadApiClient.stub :new, triage_zammad_client_mock do
      SyncIssueToTriageJob.perform_now(issue, client: triage_zammad_client_mock)
    end

    assert_equal 9, issue.owner.reload.zammad_identifier
    assert_equal 99, issue.reload.triage_external_id
  end
end
