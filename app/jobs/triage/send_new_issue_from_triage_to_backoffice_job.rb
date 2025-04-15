class Triage::SendNewIssueFromTriageToBackofficeJob < ApplicationJob
  def perform(ticket_id, triage_zammad_client: TriageZammadEnvironment.client, webhook_client: WebhookClient)
    responsible_subject_data = triage_zammad_client.find_ticket_responsible_subject(ticket_id)
    responsible_subject = ResponsibleSubject.find(responsible_subject_data[:value])

    raise "Responsible subject not found: #{responsible_subject_data[:value]}" unless responsible_subject

    client = Client.find_by!(responsible_subject: responsible_subject)
    raise "Client not found for responsible subject: #{responsible_subject_data[:value]}" unless client

    webhook_client.new(client).issue_created(ticket_id)
  end
end
