class UpdatePortalIssueStateFromTriageJob < ApplicationJob
  def perform(issue, client: TriageZammadEnvironment.client)
    ticket_state = Issues::State.find_by(name: client.client.ticket.find(issue.triage_external_id)&.state)

    raise unless ticket_state

    issue.state = ticket_state
    issue.save!
  end
end
