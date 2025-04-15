class Triage::ProcessNewActivityFromTriageJob < ApplicationJob
  def perform(ticket_id, article_id, triage_zammad_client: TriageZammadEnvironment.client, webhook_client: WebhookClient)
    responsible_subject_data = triage_zammad_client.find_ticket_responsible_subject(ticket_id)
    responsible_subject = ResponsibleSubject.find(responsible_subject_data[:value])

    return unless responsible_subject.pro?

    article = triage_zammad_client.get_article(ticket_id, article_id, responsible_subject: responsible_subject)
    return unless article

    client = Client.find_by!(responsible_subject: responsible_subject)
    webhook_client.new(client).activity_created(ticket_id, article_id, customer_activity: article[:customer_activity])
  end
end
