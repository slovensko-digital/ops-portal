class Triage::UpdatePortalActivityFromTriageJob < ApplicationJob
  def perform(ticket_id, article_id, triage_zammad_client: TriageZammadEnvironment.client)
    comment = Issues::Comment.find_by(triage_external_id: article_id.to_i)
    return Rails.logger.warn("Comment for article_id: #{article_id} not found") unless comment

    _ticket, article = triage_zammad_client.find_article(ticket_id, article_id)
    return Rails.logger.info("Article ticket_id: #{ticket_id}, article_id: #{article_id} not found") unless article

    comment.update!(hidden: article.internal) unless comment.hidden == article.internal
  end
end
