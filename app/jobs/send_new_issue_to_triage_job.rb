class SendNewIssueToTriageJob < ApplicationJob
  def perform(issue, client: TriageZammadEnvironment.client)
    ticket_id = client.create_ticket!(issue)

    raise unless ticket_id

    issue.last_synced_at = Time.now
    issue.triage_external_id = ticket_id
    issue.save!

    UpdateIssueStateFromTriageJob.perform_later(issue)
  end
end
