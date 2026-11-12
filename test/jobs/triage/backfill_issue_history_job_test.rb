require "test_helper"

class Triage::BackfillIssueHistoryJobTest < ActiveJob::TestCase
  def state_history_entry(from, to, at)
    {
      "type" => "updated", "object" => "Ticket", "attribute" => "ops_state",
      "value_from" => from, "value_to" => to, "created_at" => at
    }
  end

  def rs_history_entry(from_id, to_id, at)
    {
      "type" => "updated", "object" => "Ticket", "attribute" => "responsible_subject",
      "value_from" => rs_value(from_id), "value_to" => rs_value(to_id), "created_at" => at
    }
  end

  def rs_value(id)
    id.nil? ? "" : "{\"label\" => \"subject\", \"value\" => #{id}}"
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

  def rs_changes_for(issue)
    issue.activities.where(type: "Issues::SystemResponsibleSubjectChangeActivity").order(:created_at).map(&:activity_object)
  end

  test "merges state changes from both the triage and the resolution ticket" do
    issue = issues(:two)
    client = client_with(
      2 => [ state_history_entry("waiting", "sent_to_responsible", "2024-11-06T10:00:00.000Z") ],
      3 => [ state_history_entry("sent_to_responsible", "in_progress", "2024-11-07T10:00:00.000Z") ]
    )

    Triage::BackfillIssueHistoryJob.new.perform(issue, triage_zammad_client: client)

    changes = state_changes_for(issue)
    assert_equal 3, changes.size
    assert_equal [
                   [ nil, "waiting" ],
                   [ "waiting", "sent_to_responsible" ],
                   [ "sent_to_responsible", "in_progress" ]
                 ], changes.map { |c| [ c.previous_state&.key, c.new_state.key ] }
    assert_empty rs_changes_for(issue)
    assert_mock client
  end

  test "backfills responsible subject changes from ticket history" do
    one, two = responsible_subjects(:one), responsible_subjects(:two)
    issue = issues(:two)
    issue.update_columns(responsible_subject_id: two.id)

    client = client_with(
      2 => [ rs_history_entry(nil, one.id, "2024-11-06T10:00:00.000Z") ],
      3 => [ rs_history_entry(one.id, two.id, "2024-11-07T10:00:00.000Z") ]
    )

    Triage::BackfillIssueHistoryJob.new.perform(issue, triage_zammad_client: client)

    changes = rs_changes_for(issue)
    assert_equal 2, changes.size
    assert_equal [
                   [ nil, one.id ],
                   [ one.id, two.id ]
                 ], changes.map { |c| [ c.previous_responsible_subject_id, c.new_responsible_subject_id ] }

    assert_equal [ [ nil, "in_progress" ] ],
                 state_changes_for(issue).map { |c| [ c.previous_state&.key, c.new_state.key ] }
    assert_mock client
  end

  test "backfills state and responsible subject changes independently" do
    two = responsible_subjects(:two)
    issue = issues(:two)

    Triage::BackfillIssueHistoryJob.new.perform(
      issue,
      triage_zammad_client: client_with(
        2 => [ state_history_entry("waiting", "in_progress", "2024-11-06T10:00:00.000Z") ],
        3 => []
      )
    )
    assert_equal 2, state_changes_for(issue).size
    assert_empty rs_changes_for(issue)

    issue.update_columns(responsible_subject_id: two.id)
    Triage::BackfillIssueHistoryJob.new.perform(
      issue,
      triage_zammad_client: client_with(
        2 => [ rs_history_entry(nil, two.id, "2024-11-07T10:00:00.000Z") ],
        3 => []
      )
    )
    assert_equal 2, state_changes_for(issue).size
    assert_equal [ [ nil, two.id ] ],
                 rs_changes_for(issue).map { |c| [ c.previous_responsible_subject_id, c.new_responsible_subject_id ] }
  end

  test "is idempotent" do
    issue = issues(:two)
    issue.update_columns(responsible_subject_id: responsible_subjects(:two).id)
    history = [ state_history_entry("waiting", "in_progress", "2024-11-06T10:00:00.000Z") ]

    Triage::BackfillIssueHistoryJob.new.perform(
      issue, triage_zammad_client: client_with(2 => history, 3 => [])
    )
    assert_equal 2, state_changes_for(issue).size
    assert_equal 1, rs_changes_for(issue).size

    Triage::BackfillIssueHistoryJob.new.perform(issue, triage_zammad_client: Minitest::Mock.new)
    assert_equal 2, state_changes_for(issue).size
    assert_equal 1, rs_changes_for(issue).size
  end

  test "runs on the low priority queue" do
    assert_equal "low_priority", Triage::BackfillIssueHistoryJob.queue_name
  end

  test "backfills only the missing state prefix when live changes already exist" do
    issue = issues(:two)
    issue.update!(state: Issues::State.find_by!(key: "resolved"))

    client = client_with(
      2 => [
        state_history_entry("waiting", "sent_to_responsible", "2024-11-06T10:00:00.000Z"),
        state_history_entry("sent_to_responsible", "in_progress", "2024-11-06T11:00:00.000Z")
      ],
      3 => [ state_history_entry("in_progress", "rejected", "2024-11-07T10:00:00.000Z") ]
    )

    Triage::BackfillIssueHistoryJob.new.perform(issue, triage_zammad_client: client)

    assert_equal [
                   [ nil, "waiting" ],
                   [ "waiting", "sent_to_responsible" ],
                   [ "sent_to_responsible", "in_progress" ],
                   [ "in_progress", "resolved" ]
                 ], state_changes_for(issue).map { |c| [ c.previous_state&.key, c.new_state.key ] }
    assert_mock client
  end

  test "skips state backfill when live history diverges from Zammad history" do
    issue = issues(:two)
    issue.update!(state: Issues::State.find_by!(key: "resolved"))

    client = client_with(
      2 => [ state_history_entry("waiting", "sent_to_responsible", "2024-11-06T10:00:00.000Z") ],
      3 => []
    )

    Triage::BackfillIssueHistoryJob.new.perform(issue, triage_zammad_client: client)

    assert_equal [ [ "in_progress", "resolved" ] ],
                 state_changes_for(issue).map { |c| [ c.previous_state&.key, c.new_state.key ] }
    assert_mock client
  end

  test "stays a no-op when live changes arrive after a backfill" do
    issue = issues(:two)
    history = {
      2 => [ state_history_entry("waiting", "in_progress", "2024-11-06T10:00:00.000Z") ],
      3 => []
    }

    Triage::BackfillIssueHistoryJob.new.perform(issue, triage_zammad_client: client_with(history))
    assert_equal [
                   [ nil, "waiting" ],
                   [ "waiting", "in_progress" ]
                 ], state_changes_for(issue).map { |c| [ c.previous_state&.key, c.new_state.key ] }

    issue.update!(state: Issues::State.find_by!(key: "resolved"))

    Triage::BackfillIssueHistoryJob.new.perform(issue, triage_zammad_client: client_with(history))
    assert_equal [
                   [ nil, "waiting" ],
                   [ "waiting", "in_progress" ],
                   [ "in_progress", "resolved" ]
                 ], state_changes_for(issue).map { |c| [ c.previous_state&.key, c.new_state.key ] }
  end

  test "backfills only the missing responsible subject prefix up to the live anchor" do
    one, two = responsible_subjects(:one), responsible_subjects(:two)
    issue = issues(:two)
    issue.update_columns(responsible_subject_id: one.id)
    issue.reload
    issue.update!(responsible_subject: two)

    client = client_with(
      2 => [
        rs_history_entry(nil, one.id, "2024-11-05T10:00:00.000Z"),
        rs_history_entry(one.id, two.id, "2024-11-05T11:00:00.000Z"),
        rs_history_entry(two.id, one.id, "2024-11-05T12:00:00.000Z")
      ],
      3 => []
    )

    Triage::BackfillIssueHistoryJob.new.perform(issue, triage_zammad_client: client)

    assert_equal [
                   [ nil, one.id ],
                   [ one.id, two.id ],
                   [ two.id, one.id ],
                   [ one.id, two.id ]
                 ], rs_changes_for(issue).map { |c| [ c.previous_responsible_subject_id, c.new_responsible_subject_id ] }
    assert_mock client
  end

  test "does not prepend Zammad history when live history starts unassigned" do
    one, two = responsible_subjects(:one), responsible_subjects(:two)
    issue = issues(:two)
    issue.update!(responsible_subject: two)

    client = client_with(
      2 => [
        rs_history_entry(nil, one.id, "2024-11-05T10:00:00.000Z"),
        rs_history_entry(one.id, two.id, "2024-11-05T11:00:00.000Z")
      ],
      3 => []
    )

    Triage::BackfillIssueHistoryJob.new.perform(issue, triage_zammad_client: client)

    assert_equal [ [ nil, two.id ] ],
                 rs_changes_for(issue).map { |c| [ c.previous_responsible_subject_id, c.new_responsible_subject_id ] }
    assert_mock client
  end

  test "skips issues without any ticket" do
    issue = issues(:without_triage_external_id)
    client = Minitest::Mock.new

    Triage::BackfillIssueHistoryJob.new.perform(issue, triage_zammad_client: client)

    assert_empty state_changes_for(issue)
    assert_empty rs_changes_for(issue)
    assert_mock client
  end

  test "skips issues whose ticket no longer exists" do
    issue = issues(:two)
    client = client_with(2 => nil)

    Triage::BackfillIssueHistoryJob.new.perform(issue, triage_zammad_client: client)

    assert_empty state_changes_for(issue)
    assert_empty rs_changes_for(issue)
    assert_mock client
  end
end
