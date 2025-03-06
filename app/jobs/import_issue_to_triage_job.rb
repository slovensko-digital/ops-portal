class ImportIssueToTriageJob < ApplicationJob
  def perform(issue, zammad_group:, api: TriageZammadEnvironment.api, client: TriageZammadEnvironment.client, import_activities_to_triage_job: ImportIssueActivitiesToTriageJob)
    return if issue.triage_external_id.present?

    api.check_import_mode!

    issue.author.update!(zammad_identifier: client.create_customer!(issue.author.email)) unless issue.author.zammad_identifier.present?

    if issue.owner
      issue.owner.update!(zammad_identifier: client.create_agent!(issue.owner.email)) unless issue.owner.zammad_identifier.present?
      client.add_user_to_group(issue.owner.zammad_identifier, zammad_group)
    end

    ticket_id = client.create_ticket!(issue, group: zammad_group)

    raise unless ticket_id

    issue.update!(
      last_synced_at: Time.now,
      triage_external_id: ticket_id
    )

    import_activities_to_triage_job.perform_later(issue)
  end
end
