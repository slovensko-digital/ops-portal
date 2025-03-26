class ImportIssueToTriageJob < ApplicationJob
  def perform(issue, zammad_group:, api: TriageZammadEnvironment.api, client: TriageZammadEnvironment.client, import_activities_to_triage_job: ImportIssueActivitiesToTriageJob)
    return if issue.triage_external_id.present?

    api.check_import_mode!

    issue.author.update!(external_id: client.create_customer!(issue.author)) unless issue.author.external_id.present?

    if issue.owner
      issue.owner.update!(external_id: client.create_agent!(issue.owner)) unless issue.owner.external_id.present?
      client.add_user_to_group(issue.owner.external_id, zammad_group)
    end

    ticket_id = client.create_ticket_from_issue!(issue, group: zammad_group)

    raise unless ticket_id

    issue.update!(
      last_synced_at: Time.now,
      triage_external_id: ticket_id
    )

    import_activities_to_triage_job.perform_later(issue)
  end
end
