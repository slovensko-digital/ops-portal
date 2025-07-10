class Triage::SyncTicketUpdateFromTriageJob < ApplicationJob
  def perform(ticket_id, triage_zammad_client: TriageZammadEnvironment.client)
    ticket = triage_zammad_client.get_ticket(ticket_id)
    raise "Ticket not found" unless ticket

    case ticket[:process_type]
    when "portal_issue_triage", "portal_issue_resolution"
      update_issue(ticket)
    when "portal_issue_verification"
      update_issue_update(ticket)
    else
      raise "Process type not yet supported: #{ticket[:process_type]}"
    end
  end
end
