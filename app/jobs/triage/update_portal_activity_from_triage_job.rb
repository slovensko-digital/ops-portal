class Triage::UpdatePortalActivityFromTriageJob < ApplicationJob
  def perform(ticket_id, article_id, triage_zammad_client: TriageZammadEnvironment.client)
    activity_object = Issues::Comment.find_by(triage_external_id: article_id.to_i) || Issues::Update.find_by(triage_external_id: article_id.to_i)
    # perform, not perform_now: its retry would enqueue the job with the client, which can't be serialized, and
    # hide the real error. This job retries with serializable arguments instead.
    return ::Triage::CreateNewPortalActivityFromTriageJob.new.perform(ticket_id, article_id, triage_zammad_client: triage_zammad_client) unless activity_object

    _ticket, article = triage_zammad_client.find_article(ticket_id, article_id)
    return Rails.logger.info("Article ticket_id: #{ticket_id}, article_id: #{article_id} not found") unless article

    return if activity_object.hidden == article.internal

    activity_object.update!(hidden: article.internal)
    # hidden is part of the visible set, so the counters have to follow it
    # even though the activity itself did not change.
    activity_object.issue.reset_counters
  end
end
