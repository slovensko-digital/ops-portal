class Triage::UpdatePortalActivityFromTriageJob < ApplicationJob
  def perform(ticket_id, article_id, triage_zammad_client: TriageZammadEnvironment.client)
    activity_object = Issues::Comment.find_by(triage_external_id: article_id.to_i) || Issues::Update.find_by(triage_external_id: article_id.to_i)
    return ::Triage::CreateNewPortalActivityFromTriageJob.perform_now(ticket_id, article_id, triage_zammad_client: triage_zammad_client) unless activity_object

    _ticket, article = triage_zammad_client.find_article(ticket_id, article_id)
    return Rails.logger.info("Article ticket_id: #{ticket_id}, article_id: #{article_id} not found") unless article

    activity_object.update!(hidden: article.internal) unless activity_object.hidden == article.internal
  end
end
