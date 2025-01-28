class Triage::SendNewIssueFromTriageToBackofficeJob < ApplicationJob
  def perform(ticket_id, triage_zammad_client: TriageZammadEnvironment.client, webhook_client: WebhookClient)
    responsible_subject = triage_zammad_client.find_ticket_responsible_subject(ticket_id)
    client = Client.find_by!(responsible_subject_zammad_identifier: responsible_subject)
    webhook_client.new(client).issue_created(ticket_id)
  end
end
