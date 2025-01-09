class Triage::SendNewIssueStatusFromTriageToBackofficeJob < ApplicationJob
  def perform(ticket_id, triage_zammad_client: TriageZammadEnvironment.client, webhook_client: WebhookClient)
    responsible_subject = triage_zammad_client.ticket.find(ticket_id).responsible_subject
    backoffice_client = BackofficeClient.find_by!(responsible_subject_zammad_identifier: responsible_subject)
    webhook_client.new(backoffice_client).issue_status_updated(ticket_id)
  end
end
