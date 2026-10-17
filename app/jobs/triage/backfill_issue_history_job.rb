class Triage::BackfillIssueHistoryJob < ApplicationJob
  TRIAGE_STATE_ATTRIBUTE = "ops_state"
  TRIAGE_RESPONSIBLE_SUBJECT_ATTRIBUTE = "responsible_subject"

  def perform(issue, triage_zammad_client: TriageZammadEnvironment.client)
    ticket_ids = [ issue.triage_external_id, issue.resolution_external_id ].compact.uniq
    if ticket_ids.empty?
      log(issue, "has no triage ticket, skipped")
      return
    end
    return if state_backfilled?(issue) && responsible_subject_backfilled?(issue)

    histories = {}
    ticket_ids.each do |ticket_id|
      history = triage_zammad_client.get_ticket_history(ticket_id)
      if history.nil?
        log(issue, "ticket #{ticket_id} not found, skipped")
        return
      end
      histories[ticket_id] = history
    end

    issue.with_lock do
      backfill_state_changes(issue, histories) unless state_backfilled?(issue)
      backfill_responsible_subject_changes(issue, histories) unless responsible_subject_backfilled?(issue)
    end
  end

  private

  def log(issue, message)
    Rails.logger.info("BackfillIssueHistory: issue ##{issue.id} #{message}")
  end

  def state_backfilled?(issue)
    issue.activities.where(type: "Issues::StateChangeActivity").exists?
  end

  def responsible_subject_backfilled?(issue)
    issue.activities.where(type: "Issues::SystemResponsibleSubjectChangeActivity").exists?
  end

  def backfill_state_changes(issue, histories)
    transitions = histories.values.flat_map { |history| state_transitions(history) }
    transitions.sort_by! { |entry| entry[:created_at] || issue.created_at }

    entries = []
    if transitions.any?
      first_previous = transitions.first[:previous_state]
      entries << { previous_state: nil, new_state: first_previous, created_at: issue.created_at } if first_previous
    elsif issue.state
      entries << { previous_state: nil, new_state: issue.state, created_at: issue.created_at }
    end
    entries.concat(transitions)

    if entries.empty?
      log(issue, "has no mappable state history, skipped")
      return
    end

    last_new_state = transitions.last&.dig(:new_state)
    if last_new_state && issue.state_id && last_new_state.id != issue.state_id
      log(issue, "portal state (#{issue.state.key}) differs from last Zammad state (#{last_new_state.key}), backfilling Zammad history only")
    end

    insert_state_changes!(issue, entries)
    log(issue, "backfilled #{entries.size} state change(s)")
  end

  def backfill_responsible_subject_changes(issue, histories)
    transitions = histories.values.flat_map { |history| responsible_subject_transitions(history) }
    transitions.sort_by! { |entry| entry[:created_at] || issue.created_at }

    entries = []
    if transitions.any?
      first_previous = transitions.first[:previous_responsible_subject]
      if first_previous
        entries << { previous_responsible_subject: nil, new_responsible_subject: first_previous, created_at: issue.created_at }
      end
    elsif issue.responsible_subject
      entries << { previous_responsible_subject: nil, new_responsible_subject: issue.responsible_subject, created_at: issue.created_at }
    end
    entries.concat(transitions)

    if entries.empty?
      log(issue, "has no mappable responsible subject history, skipped")
      return
    end

    last_new_rs = transitions.last&.dig(:new_responsible_subject)
    if last_new_rs && issue.responsible_subject_id && last_new_rs.id != issue.responsible_subject_id
      log(issue, "portal responsible subject (#{issue.responsible_subject.name}) differs from last Zammad one (#{last_new_rs.name}), backfilling Zammad history only")
    end

    insert_responsible_subject_changes!(issue, entries)
    log(issue, "backfilled #{entries.size} responsible subject change(s)")
  end

  def state_transitions(history)
    history
      .select { |entry| entry["type"] == "updated" && entry["object"] == "Ticket" && entry["attribute"] == TRIAGE_STATE_ATTRIBUTE }
      .filter_map do |entry|
      new_state = find_state(entry["value_to"])

      if new_state.nil?
        Rails.logger.info("BackfillIssueHistory: unmappable triage state #{entry["value_to"].inspect}, entry skipped")
        next
      end

      previous_state = find_state(entry["value_from"])
      next if previous_state == new_state

      { previous_state: previous_state, new_state: new_state, created_at: parse_time(entry["created_at"]) }
    end
  end

  def responsible_subject_transitions(history)
    history
      .select { |entry| entry["type"] == "updated" && entry["object"] == "Ticket" && entry["attribute"] == TRIAGE_RESPONSIBLE_SUBJECT_ATTRIBUTE }
      .filter_map do |entry|
      new_rs_id = parse_responsible_subject_id(entry["value_to"])
      new_rs = ResponsibleSubject.find_by(id: new_rs_id) if new_rs_id

      if new_rs_id && new_rs.nil?
        Rails.logger.info("BackfillIssueHistory: unmappable responsible subject #{entry["value_to"].inspect}, entry skipped")
        next
      end

      previous_rs = find_responsible_subject(entry["value_from"])
      next if previous_rs == new_rs

      { previous_responsible_subject: previous_rs, new_responsible_subject: new_rs, created_at: parse_time(entry["created_at"]) }
    end
  end

  def find_state(value)
    normalized = value.to_s.strip
    return if normalized.blank?

    Issues::State.find_by(key: normalized) || Issues::State.find_by(name: normalized)
  end

  def parse_responsible_subject_id(value)
    value.to_s[/"value"\s*=>\s*(\d+)/, 1]&.to_i
  end

  def find_responsible_subject(value)
    id = parse_responsible_subject_id(value)
    ResponsibleSubject.find_by(id: id) if id
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

  def insert_responsible_subject_changes!(issue, entries)
    now = Time.current

    activity_ids = Issues::Activity.insert_all(
      entries.map { |entry|
        {
          issue_id: issue.id,
          type: "Issues::SystemResponsibleSubjectChangeActivity",
          created_at: entry[:created_at] || now,
          updated_at: now
        }
      },
      returning: %w[id]
    ).rows.flatten

    raise "activity/responsible subject change count mismatch" if activity_ids.size != entries.size

    Issues::SystemResponsibleSubjectChange.insert_all(
      entries.zip(activity_ids).map { |entry, activity_id|
        {
          activity_id: activity_id,
          previous_responsible_subject_id: entry[:previous_responsible_subject]&.id,
          new_responsible_subject_id: entry[:new_responsible_subject]&.id,
          uuid: SecureRandom.uuid,
          created_at: entry[:created_at] || now,
          updated_at: now
        }
      }
    )
  end
end
