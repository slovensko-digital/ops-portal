class SyncIssueToTriageJob < ApplicationJob
  def perform(issue, client: TriageZammadEnvironment.client, import: false, sync_activities_to_triage_job: SyncIssueActivitiesToTriageJob, sync_activities: true)
    client.check_import_mode! if import

    if issue.resolution_external_id.present?
      client.update_ticket_from_issue!(issue.resolution_external_id, issue)
      issue.touch(:last_synced_at)

    elsif issue.triage_external_id.present?
      client.update_ticket_from_issue!(issue.triage_external_id, issue)
      issue.touch(:last_synced_at)

    else
      ticket_id = create_new_triage_ticket(issue, client, import)
      raise unless ticket_id

      issue.update!(
        last_synced_at: Time.now,
        triage_external_id: ticket_id
      )
    end

    sync_activities_to_triage_job.perform_later(issue, import: import) if sync_activities
  end

  private

  def create_new_triage_ticket(issue, client, import)
    find_or_create_triage_portal_user!(issue.author, client) unless issue.author.external_id

    return client.create_ticket_from_issue!(issue) unless import

    zammad_group = find_municipality_group(issue, client)
    if issue.owner
      find_or_create_triage_portal_user!(issue.owner, client, customer: false) unless issue.owner.external_id
      client.add_user_to_group(issue.owner.external_id, zammad_group)
    end

    client.create_ticket_from_issue!(
      issue,
      process_type: ISSUE_STATE_TO_PROCESS_TYPE.fetch(issue.state.name),
      group: zammad_group,
      owner_id: issue.owner&.external_id
    )
  end

  def find_or_create_triage_portal_user!(user, client, customer: true)
    return user if user.external_id

    user.external_id = if customer
     client.create_customer!(user)
    else
     client.create_agent!(user)
    end
    user.save!

    user
  end

  def find_municipality_group(issue, client)
    if issue.municipality_district
      client.get_groups.select { |group| issue.municipality.name.in?(group.name) && issue.municipality_district.name&.in?(group.name) }[0].name
    else
      client.get_groups.select { |group| issue.municipality.name.in?(group.name) }[0].name
    end
  end

  ISSUE_STATE_TO_PROCESS_TYPE = {
    "Neriešený" => "portal_issue_resolution",
    "Vyriešený" => "portal_issue_resolution",
    "V riešení" => "portal_issue_resolution",
    "Uzavretý" => "portal_issue_resolution",
    "Čakajúci" => "portal_issue_triage",
    "Neprijatý" => "portal_issue_triage"
  }
end
