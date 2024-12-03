class Triage::SendNewIssueStatusToIntegrationJob < ApplicationJob
  def perform(ticket_id, triage_zammad_client: TriageZammadEnvironment.client, webhook_client: WebhookClient)
    responsible_subject = triage_zammad_client.ticket.find(ticket_id).responsible_subject
    api_integration = ApiIntegration.find_by!(responsible_subject_zammad_identifier: responsible_subject)
    webhook_client.new(api_integration).issue_status_updated(ticket_id)
  end
end
