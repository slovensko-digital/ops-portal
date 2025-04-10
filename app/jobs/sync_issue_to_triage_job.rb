class SyncIssueToTriageJob < ApplicationJob
  def perform(issue, client: TriageZammadEnvironment.client, import: false, sync_activities_to_triage_job: SyncIssueActivitiesToTriageJob)
    client.check_import_mode! if import

    # TODO actually do a sync (insert/update & handle triage_process/resolution_process)
    find_or_create_triage_portal_user!(issue.author, client) unless issue.author.external_id

    zammad_group = find_municipality_group(issue, client)

    if issue.owner
      find_or_create_triage_portal_user!(issue.owner, client, customer: false) unless issue.owner.external_id
      client.add_user_to_group(issue.owner.external_id, zammad_group.name)
    end

    process_type = ISSUE_STATE_TO_PROCESS_TYPE.fetch(issue.state.name)
    title = process_type == "portal_issue_triage" ? "Triáž: #{issue.title}" : issue.title
    likes_count = issue.legacy_data ? issue.legacy_data["like_count"] : 999 # TODO handle also non legacy

    if issue.triage_external_id.present?
      client.update_ticket_from_issue!(issue.triage_external_id, issue, title: title, likes_count: likes_count)
      issue.update!(
        last_synced_at: Time.now
      )
    else
      issue_type = "issue" # TODO fix in import ... add issue.issue_type

      ticket_id = client.create_ticket_from_issue!(
        issue,
        issue_type: issue.issue_type,
        process_type: process_type,
        title: title,
        description: issue.description.presence || "(bez popisu)",
        portal_url: Rails.application.routes.url_helpers.issue_url(issue),
        responsible_subject: issue.responsible_subject,
        likes_count: likes_count,
        group: zammad_group.name
      )

      raise unless ticket_id

      issue.update!(
        last_synced_at: Time.now,
        triage_external_id: ticket_id
      )
    end

    sync_activities_to_triage_job.perform_later(issue, import: import)
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
      client.get_groups.select { |group| issue.municipality.name.in?(group.name) && issue.municipality_district.name&.in?(group.name) }[0]
    else
      client.get_groups.select { |group| issue.municipality.name.in?(group.name) }[0]
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
