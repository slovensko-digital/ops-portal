class Triage::BackfillIssueStateChangesJob < ApplicationJob
  TRIAGE_STATE_ATTRIBUTE = "ops_state"

  def perform(issue, triage_zammad_client: TriageZammadEnvironment.client)
    ticket_ids = [ issue.triage_external_id, issue.resolution_external_id ].compact.uniq
    if ticket_ids.empty?
      Rails.logger.info("BackfillIssueStateChanges: issue ##{issue.id} has no triage ticket, skipped")
      return
    end
    return if backfilled?(issue)

    transitions = ticket_ids.flat_map do |ticket_id|
      history = triage_zammad_client.get_ticket_history(ticket_id)

      if history.nil?
        Rails.logger.info("BackfillIssueStateChanges: ticket #{ticket_id} (issue ##{issue.id}) not found, skipped")
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
      Rails.logger.info("BackfillIssueStateChanges: issue ##{issue.id} has no mappable state history, skipped")
      return
    end

    last_new_state = transitions.last&.dig(:new_state)
    if last_new_state && issue.state_id && last_new_state.id != issue.state_id
      Rails.logger.info("BackfillIssueStateChanges: issue ##{issue.id} portal state (#{issue.state.key}) differs from last Zammad state (#{last_new_state.key}), backfilling Zammad history only")
    end

    issue.with_lock do
      return if backfilled?(issue)

      Issues::StateChange.transaction do
        insert_state_changes!(issue, entries)
      end
    end

    Rails.logger.info("BackfillIssueStateChanges: issue ##{issue.id} backfilled #{entries.size} state change(s) from tickets #{ticket_ids.join(", ")}")
  end

  private

  def backfilled?(issue)
    issue.activities.exists?(type: "Issues::StateChangeActivity")
  end

  def state_transitions(history)
    history
      .select { |entry| entry["type"] == "updated" && entry["object"] == "Ticket" && entry["attribute"] == TRIAGE_STATE_ATTRIBUTE }
      .filter_map do |entry|
      new_state = find_state(entry["value_to"])

      if new_state.nil?
        Rails.logger.info("BackfillIssueStateChanges: unmappable triage state #{entry["value_to"].inspect}, entry skipped")
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
