
class BackfillIssueStateChangesFromTriageHistory < ActiveRecord::Migration[8.1]
  TRIAGE_STATE_ATTRIBUTE = "ops_state"

  def up
    issues = Issue.where.not(triage_external_id: nil)
                  .or(Issue.where.not(resolution_external_id: nil))

    say_with_time "Backfilling state changes for #{issues.count} issues with tickets" do
      issues.find_each do |issue|
        backfill_issue(issue)
      rescue StandardError => e
        say "  issue ##{issue.id}: skipped (#{e.class}: #{e.message})", true
      end
    end
  end

  def down
    Issues::StateChange.where.not(triage_external_id: nil).find_each(&:destroy!)
  end

  private

  def ticket_ids(issue)
    [ issue.triage_external_id, issue.resolution_external_id ].compact.uniq
  end

  def backfilled?(issue)
    Issues::StateChange.where(triage_external_id: ticket_ids(issue)).exists?
  end

  def backfill_issue(issue)
    return if backfilled?(issue)

    transitions = ticket_ids(issue).flat_map do |ticket_id|
      history = TriageZammadEnvironment.client.get_ticket_history(ticket_id)

      if history.nil?
        say "  issue ##{issue.id}: ticket #{ticket_id} not found, skipped", true
        return
      end

      state_transitions(history)
    end

    transitions.sort_by! { |entry| entry[:created_at] || issue.created_at }

    initial_state = transitions.first&.dig(:previous_state) || issue.state

    entries = []
    if initial_state
      entries << {
        previous_state: nil,
        new_state: initial_state,
        created_at: issue.created_at
      }
    end

    entries.concat(transitions)

    if entries.empty?
      say "  issue ##{issue.id}: no mappable state history, skipped", true
      return
    end

    last_new_state = transitions.last&.dig(:new_state)
    if last_new_state && issue.state_id && last_new_state.id != issue.state_id
      say "  issue ##{issue.id}: portal state (#{issue.state.key}) differs from last Zammad state (#{last_new_state.key}), backfilling Zammad history only", true
    end

    Issues::StateChange.transaction do
      insert_state_changes!(issue, entries)
    end

    say "  issue ##{issue.id}: backfilled #{entries.size} state change(s) from tickets #{ticket_ids(issue).join(', ')}", true
  end

  def state_transitions(history)
    history
      .select { |entry| entry["type"] == "updated" && entry["object"] == "Ticket" && entry["attribute"] == TRIAGE_STATE_ATTRIBUTE }
      .filter_map do |entry|
      new_state = find_state(entry["value_to"])

      if new_state.nil?
        say "    unmappable triage state #{entry["value_to"].inspect}, entry skipped", true
        next
      end

      previous_state = find_state(entry["value_from"])
      next if previous_state == new_state

      { previous_state: previous_state, new_state: new_state, created_at: parse_time(entry["created_at"]) }
    end
  end

  def find_state(value)
    normalized = value.to_s.strip
    return if normalized.blank?

    Issues::State.find_by(key: normalized) || Issues::State.find_by(name: normalized)
  end

  def parse_time(value)
    Time.zone.parse(value.to_s)
  rescue StandardError
    nil
  end

  def insert_state_changes!(issue, entries)
    now = Time.current

    activity_ids = Issues::Activity.insert_all(
      entries.map { |entry|
        {
          issue_id: issue.id,
          type: "Issues::StateChangeActivity",
          created_at: entry[:created_at] || now,
          updated_at: now
        }
      },
      returning: %w[id]
    ).rows.flatten

    raise "activity/state change count mismatch" if activity_ids.size != entries.size

    Issues::StateChange.insert_all(
      entries.zip(activity_ids).map { |entry, activity_id|
        {
          activity_id: activity_id,
          previous_state_id: entry[:previous_state]&.id,
          new_state_id: entry[:new_state].id,
          uuid: SecureRandom.uuid,
          created_at: entry[:created_at] || now,
          updated_at: now
        }
      }
    )
  end
end
