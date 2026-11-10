class Triage::BackfillIssueHistoryJob < ApplicationJob
  queue_as :low_priority

  TRIAGE_STATE_ATTRIBUTE = "ops_state"
  TRIAGE_RESPONSIBLE_SUBJECT_ATTRIBUTE = "responsible_subject"

  def perform(issue, triage_zammad_client: TriageZammadEnvironment.client)
    ticket_ids = [ issue.triage_external_id, issue.resolution_external_id ].compact.uniq
    if ticket_ids.empty?
      log(issue, "has no triage ticket, skipped")
      return
    end
    return if state_backfill_done?(issue) && responsible_subject_backfill_done?(issue)

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
      backfill_state_changes(issue, histories) unless state_backfill_done?(issue)
      backfill_responsible_subject_changes(issue, histories) unless responsible_subject_backfill_done?(issue)
    end
  end

  private

  def log(issue, message)
    Rails.logger.info("BackfillIssueHistory: issue ##{issue.id} #{message}")
  end

  def state_backfill_done?(issue)
    oldest = oldest_state_change(issue)
    oldest ? oldest.previous_state_id.nil? : false
  end

  def responsible_subject_backfill_done?(issue)
    oldest = oldest_responsible_subject_change(issue)
    oldest ? oldest.previous_responsible_subject_id.nil? && oldest.activity.created_at == issue.created_at : false
  end

  def oldest_state_change(issue)
    issue.activities.where(type: "Issues::StateChangeActivity").order(:id).first&.activity_object
  end

  def oldest_responsible_subject_change(issue)
    issue.activities.where(type: "Issues::SystemResponsibleSubjectChangeActivity").order(:id).first&.activity_object
  end

  def backfill_state_changes(issue, histories)
    transitions = histories.values.flat_map { |history| state_transitions(history) }
    transitions.sort_by! { |entry| entry[:created_at] || issue.created_at }

    oldest = oldest_state_change(issue)
    reconciling = !oldest.nil?

    if reconciling
      anchor_state_id = oldest.previous_state_id
      index = transitions.rindex { |entry| entry[:new_state].id == anchor_state_id }

      if index.nil?
        if anchor_state_id.nil?
          log(issue, "live state history starts with an unknown state, nothing to prepend")
        else
          anchor_key = Issues::State.find_by(id: anchor_state_id)&.key || "##{anchor_state_id}"
          Rails.logger.warn("BackfillIssueHistory: issue ##{issue.id} live state history starts at #{anchor_key}, not found in Zammad history, skipped")
        end
        return
      end

      dropped = transitions.size - index - 1
      transitions = transitions[0..index]
      log(issue, "reconciling with live history, #{dropped} newer Zammad change(s) superseded") if dropped.positive?
    end

    entries = []
    if transitions.any?
      first_previous = transitions.first[:previous_state]
      entries << { previous_state: nil, new_state: first_previous, created_at: issue.created_at } if first_previous
    elsif issue.state && !reconciling
      entries << { previous_state: nil, new_state: issue.state, created_at: issue.created_at }
    end
    entries.concat(transitions)

    if entries.empty?
      log(issue, "has no mappable state history, skipped")
      return
    end

    unless reconciling
      last_new_state = transitions.last&.dig(:new_state)
      if last_new_state && issue.state_id && last_new_state.id != issue.state_id
        log(issue, "portal state (#{issue.state.key}) differs from last Zammad state (#{last_new_state.key}), backfilling Zammad history only")
      end
    end

    insert_state_changes!(issue, entries)
    log(issue, "backfilled #{entries.size} state change(s)")
  end

  def backfill_responsible_subject_changes(issue, histories)
    transitions = histories.values.flat_map { |history| responsible_subject_transitions(history) }
    transitions.sort_by! { |entry| entry[:created_at] || issue.created_at }

    oldest = oldest_responsible_subject_change(issue)
    reconciling = !oldest.nil?

    if reconciling
      anchor_rs_id = oldest.previous_responsible_subject_id
      index = transitions.rindex { |entry| entry[:new_responsible_subject]&.id == anchor_rs_id }

      if index.nil?
        if anchor_rs_id.nil?
          log(issue, "live responsible subject history starts unassigned, nothing to prepend")
        else
          Rails.logger.warn("BackfillIssueHistory: issue ##{issue.id} live responsible subject history starts at subject ##{anchor_rs_id}, not found in Zammad history, skipped")
        end
        return
      end

      dropped = transitions.size - index - 1
      transitions = transitions[0..index]
      log(issue, "reconciling with live history, #{dropped} newer Zammad change(s) superseded") if dropped.positive?
    end

    entries = []
    if transitions.any?
      first_previous = transitions.first[:previous_responsible_subject]
      if first_previous
        entries << { previous_responsible_subject: nil, new_responsible_subject: first_previous, created_at: issue.created_at }
      end
    elsif issue.responsible_subject && !reconciling
      entries << { previous_responsible_subject: nil, new_responsible_subject: issue.responsible_subject, created_at: issue.created_at }
    end
    entries.concat(transitions)

    if entries.empty?
      log(issue, "has no mappable responsible subject history, skipped")
      return
    end

    unless reconciling
      last_new_rs = transitions.last&.dig(:new_responsible_subject)
      if last_new_rs && issue.responsible_subject_id && last_new_rs.id != issue.responsible_subject_id
        log(issue, "portal responsible subject (#{issue.responsible_subject.name}) differs from last Zammad one (#{last_new_rs.name}), backfilling Zammad history only")
      end
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
        next if Issue.supplement_loop_transition?(previous_state, new_state)

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
