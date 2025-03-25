class SyncIssueToTriageJob < ApplicationJob
  def perform(issue, client: TriageZammadEnvironment.client)
    # TODO actually do a sync (insert/update & handle triage_process/resolution_process)
    find_or_create_triage_portal_user!(issue.author, client) unless issue.author.zammad_identifier

    if issue.owner
      find_or_create_triage_portal_user!(issue.owner, client, customer: false) unless issue.owner.zammad_identifier

      zammad_group = find_municipality_group(issue, client)
      client.add_user_to_group(issue.owner.zammad_identifier, zammad_group.name)
    end

    process_type = ISSUE_STATE_TO_PROCESS_TYPE.fetch(issue.state.name)
    title = process_type == "portal_issue_triage" ? "Triáž: #{issue.title}" : issue.title

    if issue.triage_external_id.present?
      client.update_ticket!(issue.triage_external_id, issue.attributes.merge!({ "title" => title }))
      issue.update!(
        last_synced_at: Time.now
      )
    else
      issue_type = "issue" # TODO fix in import ... add issue.issue_type
      # TODO map non-legacy responsible subjects by ID?
      responsible_subject = issue.responsible_subject&.legacy_id || issue.responsible_subject&.id # TODO map to responsible_subjects in triage
      likes_count = issue.legacy_data ? issue.legacy_data["like_count"] : 999 # TODO handle also non legacy

      ticket_id = client.create_ticket!(
        issue,
        issue_type: issue_type,
        process_type: process_type,
        title: title,
        description: issue.description.presence || "(bez popisu)",
        responsible_subject: responsible_subject,
        likes_count: likes_count
      )

      raise unless ticket_id

      issue.update!(
        last_synced_at: Time.now,
        triage_external_id: ticket_id
      )
    end
  end

  def find_or_create_triage_portal_user!(user, client, customer: true)
    return user if user.zammad_identifier

    user.zammad_identifier = if customer
     client.create_customer!(user)
    else
     client.create_agent!(user)
    end
    user.save!

    user
  end

  def find_municipality_group(issue, client)
    return client.get_groups.select { |group| issue.municipality.name.in?(group.name) }[0] unless issue.municipality_district

    client.get_groups.select { |group| issue.municipality.name.in?(group.name) && issue.municipality_district.name&.in?(group.name) }[0]
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
