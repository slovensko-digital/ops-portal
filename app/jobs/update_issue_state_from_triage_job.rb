class UpdateIssueStateFromTriageJob < ApplicationJob
  def perform(issue, client: TriageZammadEnvironment.client)
    ticket_state = client.client.ticket.find(issue.triage_external_id)&.state

    raise unless ticket_state

    issue.state = ticket_state
    issue.save!
  end
end
