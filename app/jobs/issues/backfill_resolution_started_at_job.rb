class Issues::BackfillResolutionStartedAtJob < ApplicationJob
  def perform(issue, client: TriageZammadEnvironment.client)
    ticket = client.client.ticket.find(issue.resolution_external_id)

    raw_created_at = ticket.created_at
    raise "ticket missing created_at for issue #{issue.id} external_id=#{issue.resolution_external_id}" if raw_created_at.blank?

    parsed_time = raw_created_at.is_a?(Time) ? raw_created_at : Time.iso8601(raw_created_at.to_s)
    issue.update!(resolution_started_at: parsed_time)
  end
end
