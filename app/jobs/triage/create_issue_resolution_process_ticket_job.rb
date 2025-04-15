class Triage::CreateIssueResolutionProcessTicketJob < ApplicationJob
  def perform(issue, triage_group:, triage_owner_id:, triage_zammad_client: TriageZammadEnvironment.client)
    resolution_external_id = triage_zammad_client.create_ticket_from_issue!(
      issue,
      process_type: "portal_issue_resolution",
      **{
        group: triage_group,
        owner_id: triage_owner_id
      }.compact
    )

    issue.update!(
      resolution_external_id: resolution_external_id,
      last_synced_at: Time.now
    )

    triage_zammad_client.link_tickets!(
      parent_ticket_id: issue.triage_external_id,
      child_ticket_id: resolution_external_id
    )

    triage_zammad_client.create_internal_system_note!(
      issue.triage_external_id,
      "Triáž podnetu bola ukončená a bol vytvorený nový tiket na jeho vyriešenie."
    )

    triage_zammad_client.close_ticket!(issue.triage_external_id)
  end
end
