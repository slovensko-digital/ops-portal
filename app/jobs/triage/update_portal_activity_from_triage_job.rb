class Triage::UpdatePortalActivityFromTriageJob < ApplicationJob
  def perform(ticket_id, article_id, triage_zammad_client: TriageZammadEnvironment.client)
    activity_object = Issues::Comment.find_by(triage_external_id: article_id.to_i) || Issues::Update.find_by(triage_external_id: article_id.to_i)
    return import_new_activity(ticket_id, article_id, triage_zammad_client) unless activity_object

    _ticket, article = triage_zammad_client.find_article(ticket_id, article_id)
    return Rails.logger.info("Article ticket_id: #{ticket_id}, article_id: #{article_id} not found") unless article

    activity_object.update!(hidden: article.internal) unless activity_object.hidden == article.internal
  end

  private

  def import_new_activity(ticket_id, article_id, triage_zammad_client)
    # Triage sends article.updated for an article in any ticket, not only a portal one. get_ticket returns nil
    # for a ticket that isn't a portal ticket or no longer exists, and there is nothing to import from it.
    unless triage_zammad_client.get_ticket(ticket_id)
      return Rails.logger.info("Ticket #{ticket_id} is not a portal ticket, skipping article #{article_id}")
    end

    # perform, not perform_now: its retry would enqueue the job with the client, which can't be serialized, and
    # hide the real error. This job retries with serializable arguments instead.
    ::Triage::CreateNewPortalActivityFromTriageJob.new.perform(ticket_id, article_id, triage_zammad_client: triage_zammad_client)
  end
end
