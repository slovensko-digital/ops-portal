class Triage::ProcessNewCommentFromTriageJob < ApplicationJob
  SECRET_MESSAGE_PREFIX = "<secret>"
  PRIVATE_MESSAGE_PREFIX = "<private>"
  PUBLIC_MESSAGE_PREFIX = ""

  def perform(ticket_id, article_id, triage_zammad_client: TriageZammadEnvironment.client, webhook_client: WebhookClient)
    article = triage_zammad_client.get_article(ticket_id, article_id)
    return if article[:body].starts_with? SECRET_MESSAGE_PREFIX

    if article[:body].starts_with?(PRIVATE_MESSAGE_PREFIX) || article[:body].starts_with?(PUBLIC_MESSAGE_PREFIX)
      responsible_subject = triage_zammad_client.find_ticket_responsible_subject(ticket_id)
      client = Client.find_by!(responsible_subject_zammad_identifier: responsible_subject)
      webhook_client.new(client).comment_created(ticket_id)
    end

    if article[:body].starts_with? PUBLIC_MESSAGE_PREFIX
      # send to frontend
    end
  end
end
