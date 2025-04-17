class Triage::UpdatePortalIssueFromTriageJob < ApplicationJob
  def perform(ticket_id, triage_zammad_client: TriageZammadEnvironment.client, create_issue_resolution_process_ticket_job: Triage::CreateIssueResolutionProcessTicketJob)
    ticket = triage_zammad_client.get_ticket(ticket_id)
    raise "Ticket not found" unless ticket

    issue = Issue.find_by!(triage_external_id: ticket_id)

    # TODO: update issue.description from custom TextArea field from Triage

    issue.update!(
      title: ticket[:title],
      description: ticket[:description],
      municipality: ticket[:municipality],
      municipality_district: ticket[:municipality_district],
      address_region: ticket[:address_state],
      address_district: ticket[:address_county],
      address_postcode: ticket[:address_postcode],
      address_street: ticket[:address_street],
      address_house_number: ticket[:address_house_number],
      latitude: ticket[:address_lat],
      longitude: ticket[:address_lon],
      category: ticket[:category],
      subcategory: ticket[:subcategory],
      subtype: ticket[:subtype],
      state: ticket[:ops_state],
      responsible_subject: ticket[:responsible_subject],
    )

    return unless issue.should_create_resolution_process?

    create_issue_resolution_process_ticket_job.perform_later(issue, triage_group: ticket[:group], triage_owner_id: ticket[:owner_id])
  end
end
