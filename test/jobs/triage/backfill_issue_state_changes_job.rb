require "test_helper"

class Triage::BackfillIssueStateChangesJobTest < ActiveJob::TestCase
  def history_entry(from, to, at)
    {
      "type" => "updated", "object" => "Ticket", "attribute" => "ops_state",
      "value_from" => from, "value_to" => to, "created_at" => at
    }
  end

  def client_with(histories_by_ticket_id)
    client = Minitest::Mock.new
    histories_by_ticket_id.each do |ticket_id, history|
      client.expect(:get_ticket_history, history, [ ticket_id ])
    end
    client
  end

  def state_changes_for(issue)
    issue.activities.where(type: "Issues::StateChangeActivity").order(:created_at).map(&:activity_object)
  end

  test "merges state changes from both the triage and the resolution ticket" do
    issue = issues(:two)
    client = client_with(
      2 => [ history_entry("waiting", "sent_to_responsible", "2024-11-06T10:00:00.000Z") ],
      3 => [ history_entry("sent_to_responsible", "in_progress", "2024-11-07T10:00:00.000Z") ]
    )

    Triage::BackfillIssueStateChangesJob.new.perform(issue, triage_zammad_client: client)

    changes = state_changes_for(issue)
    assert_equal 3, changes.size
    assert_equal [
                   [ nil, "waiting" ],
                   %w[waiting sent_to_responsible],
                   %w[sent_to_responsible in_progress]
                 ], changes.map { |c| [ c.previous_state&.key, c.new_state.key ] }
    assert_mock client
  end

  test "backfills Zammad history only when it does not reach the current state" do
    issue = issues(:one)
    client = client_with(
      1 => [ history_entry("waiting", "in_progress", "2024-11-06T10:00:00.000Z") ],
      42 => []
    )

    Triage::BackfillIssueStateChangesJob.new.perform(issue, triage_zammad_client: client)

    changes = state_changes_for(issue)
    assert_equal [ "waiting", "in_progress" ], changes.map { |c| c.new_state.key }
    assert_equal "in_progress", changes.last.new_state.key
    assert_mock client
  end

  test "is idempotent" do
    issue = issues(:two)
    history = [ history_entry("waiting", "in_progress", "2024-11-06T10:00:00.000Z") ]

    Triage::BackfillIssueStateChangesJob.new.perform(
      issue, triage_zammad_client: client_with(2 => history, 3 => [])
    )
    assert_equal 2, state_changes_for(issue).size

    Triage::BackfillIssueStateChangesJob.new.perform(issue, triage_zammad_client: Minitest::Mock.new)
    assert_equal 2, state_changes_for(issue).size
  end

  test "skips issues without any ticket" do
    issue = issues(:without_triage_external_id)
    client = Minitest::Mock.new

    Triage::BackfillIssueStateChangesJob.new.perform(issue, triage_zammad_client: client)

    assert_empty state_changes_for(issue)
    assert_mock client
  end

  test "skips issues whose ticket no longer exists" do
    issue = issues(:two)
    client = client_with(2 => nil)

    Triage::BackfillIssueStateChangesJob.new.perform(issue, triage_zammad_client: client)

    assert_empty state_changes_for(issue)
    assert_mock client
  end
end
