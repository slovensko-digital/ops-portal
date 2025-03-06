class ImportIssueToTriageJob < ApplicationJob
  def perform(issue, api: TriageZammadEnvironment.api, client: TriageZammadEnvironment.client, send_activities_to_triage_job: ImportIssueActivitiesToTriageJob)
    return if issue.triage_external_id.present?

    api.check_import_mode!

    issue.author.update!(zammad_identifier: client.create_customer!(issue.author.email)) unless issue.author.zammad_identifier.present?

    # TODO nastavit aj skupinu, inak sa vlastnik nepriradi k ticketu
    issue.owner&.update!(zammad_identifier: client.create_agent!(issue.owner&.email)) if issue.owner && !issue.owner&.zammad_identifier&.present?

    ticket_id = client.create_ticket!(issue)

    raise unless ticket_id

    issue.update!(
      last_synced_at: Time.now,
      triage_external_id: ticket_id
    )

    send_activities_to_triage_job.perform_later(issue)
  end
end
