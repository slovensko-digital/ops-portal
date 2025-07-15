class Triage::UpdatePortalIssueFromTriageJob < ApplicationJob
  def perform(ticket, triage_zammad_client: TriageZammadEnvironment.client)
    issue = if ticket[:process_type] == "portal_issue_triage"
      Issue.find_by!(triage_external_id: ticket[:triage_identifier])
    elsif ticket[:process_type] == "portal_issue_resolution"
      Issue.find_by!(resolution_external_id: ticket[:triage_identifier])
    else
      raise "Invalid process type"
    end

    ops_state = ticket[:ops_state]
    if ticket[:issue_type] == "praise" && ops_state.key == "unresolved"
      ops_state = Issues::State.find_by!(key: "resolved_private")
    end

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
      state: ops_state,
      responsible_subject: ticket[:responsible_subject],
      issue_type: ticket[:issue_type],
    )

    return unless issue.should_create_resolution_process?

    Triage::CreateIssueResolutionProcessTicketJob.perform_later(issue, triage_group: ticket[:triage_group], triage_owner_id: ticket[:triage_owner_id])
  end
end
