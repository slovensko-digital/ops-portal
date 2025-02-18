class Triage::ProcessNewCommentFromTriageJob < ApplicationJob
  FRONTEND_MESSAGE_TAG = "<portal>"
  BACKOFFICE_MESSAGE_TAG = "<zodpovedny>"

  def perform(ticket_id, article_id, triage_zammad_client: TriageZammadEnvironment.client, webhook_client: WebhookClient)
    article = triage_zammad_client.get_article(ticket_id, article_id)

    if article[:body].include? BACKOFFICE_MESSAGE_TAG
      responsible_subject = triage_zammad_client.find_ticket_responsible_subject(ticket_id)
      client = Client.find_by!(responsible_subject_zammad_identifier: responsible_subject)
      webhook_client.new(client).comment_created(ticket_id)
    end

    if article[:body].include? FRONTEND_MESSAGE_TAG
      # TODO send to frontend
    end
  end
end
