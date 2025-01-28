class Triage::SendNewCommentFromTriageToBackofficeJob < ApplicationJob
  def perform(ticket_id, article_id, triage_zammad_client: TriageZammadEnvironment.client, webhook_client: WebhookClient)
    responsible_subject = triage_zammad_client.ticket.find(ticket_id).responsible_subject
    client = Client.find_by!(responsible_subject_zammad_identifier: responsible_subject)
    webhook_client.new(client).comment_created(ticket_id, article_id)
  end
end
