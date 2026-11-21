class Connector::ProcessBackofficeArticleVisibilityJob < ApplicationJob
  VISIBILITY_WINDOW = 24.hours

  def perform(tenant, ticket_id, article_id, zammad_api_client: Connector::BackofficeZammadEnvironment.client(tenant), triage_zammad_client: TriageZammadEnvironment.client)
    article = zammad_api_client.get_article(ticket_id, article_id)
    return unless article && within_visibility_window?(article)

    activity = tenant.activities.find_by(backoffice_external_id: article_id)

    # internal articles are not sent to triage, so a newly public one has no activity yet
    if activity&.triage_external_id.nil?
      Connector::SendNewActivityToTriageFromBackofficeJob.perform_later(tenant, ticket_id, article_id) if article.internal == false && tenant.issues.exists?(backoffice_external_id: ticket_id)
      return
    end

    triage_zammad_client.update_article_internal!(activity.triage_external_id, article.internal)
    update_issue_state(activity, article.internal, triage_zammad_client)
  end

  private

  # measured from the article timestamps, so a delayed webhook does not move the window
  def within_visibility_window?(article)
    Time.zone.parse(article.updated_at) <= Time.zone.parse(article.created_at) + VISIBILITY_WINDOW
  end

  def update_issue_state(activity, internal, triage_zammad_client)
    comment = Issues::ResponsibleSubjectComment.find_by(triage_external_id: activity.triage_external_id)
    return unless comment

    issue = comment.issue
    state = if internal
      "sent_to_responsible" if issue.state&.key == "in_progress" && issue.comments.none? { |c| c != comment && c.is_a?(Issues::ResponsibleSubjectComment) && c.visible? }
    else
      "in_progress" if issue.state&.key.in?(%w[sent_to_responsible unresolved])
    end

    triage_zammad_client.update_ticket!(issue.resolution_external_id || issue.triage_external_id, { "ops_state" => state }) if state
  end
end
