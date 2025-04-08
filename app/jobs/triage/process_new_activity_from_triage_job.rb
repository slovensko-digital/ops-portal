class Triage::ProcessNewActivityFromTriageJob < ApplicationJob
  RESPONSIBLE_SUBJECT_ARTICLE_TAG = ENV.fetch("RESPONSIBLE_SUBJECT_ARTICLE_TAG", "[[pre zodpovedny subjekt]]")

  def perform(ticket_id, article_id, triage_zammad_client: TriageZammadEnvironment.client, webhook_client: WebhookClient)
    article = triage_zammad_client.get_article(ticket_id, article_id)
    raise "Article not found" unless article

    return unless article[:body].include?(RESPONSIBLE_SUBJECT_ARTICLE_TAG)

    responsible_subject_data = triage_zammad_client.find_ticket_responsible_subject(ticket_id)
    responsible_subject = ResponsibleSubject.find(responsible_subject_data[:value])

    return unless responsible_subject.pro?

    client = Client.find_by!(responsible_subject: responsible_subject)
    webhook_client.new(client).activity_created(ticket_id, article_id, customer_activity: !article[:body].include?(RESPONSIBLE_SUBJECT_ARTICLE_TAG))
  end
end
