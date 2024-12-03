class Triage::SendNewCommentToIntegrationJob < ApplicationJob
  def perform(ticket_id, article_id, triage_zammad_client: TriageZammadEnvironment.client, webhook_client: WebhookClient)
    responsible_subject = triage_zammad_client.ticket.find(ticket_id).responsible_subject
    api_integration = ApiIntegration.find_by!(responsible_subject_zammad_identifier: responsible_subject)
    webhook_client.new(api_integration).comment_created(ticket_id, article_id)
  end
end
