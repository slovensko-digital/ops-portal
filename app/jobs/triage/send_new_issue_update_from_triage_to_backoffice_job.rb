class Triage::SendNewIssueUpdateFromTriageToBackofficeJob < ApplicationJob
  def perform(ticket_id, triage_zammad_client: TriageZammadEnvironment.client, webhook_client: WebhookClient)
    responsible_subject_data = triage_zammad_client.find_ticket_responsible_subject(ticket_id)
    responsible_subject = ResponsibleSubject.find(responsible_subject_data[:value])

    return unless responsible_subject.pro?

    client = Client.find_by!(responsible_subject: responsible_subject)
    webhook_client.new(client).issue_updated(ticket_id)
  end
end
