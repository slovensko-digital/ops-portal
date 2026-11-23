class Connector::ProcessBackofficeArticleVisibilityJob < ApplicationJob
  VISIBILITY_WINDOW = 24.hours

  def perform(tenant, ticket_id, article_id, zammad_api_client: Connector::BackofficeZammadEnvironment.client(tenant), triage_zammad_client: TriageZammadEnvironment.client)
    article = zammad_api_client.get_article(ticket_id, article_id)
    return unless article && within_visibility_window?(article)

    triage_article_id = tenant.activities.find_by(backoffice_external_id: article_id)&.triage_external_id

    if triage_article_id
      sync_visibility(triage_article_id, article.internal, triage_zammad_client)
    elsif article.internal == false && tenant.issues.exists?(backoffice_external_id: ticket_id)
      Connector::SendNewActivityToTriageFromBackofficeJob.perform_later(tenant, ticket_id, article_id)
    end
  end

  private

  def within_visibility_window?(article)
    Time.zone.parse(article.updated_at) <= Time.zone.parse(article.created_at) + VISIBILITY_WINDOW
  end

  def sync_visibility(triage_article_id, hidden, triage_zammad_client)
    comment = Issues::ResponsibleSubjectComment.find_by(triage_external_id: triage_article_id)
    return if comment&.hidden == hidden

    triage_zammad_client.update_article_internal!(triage_article_id, hidden)
    sync_issue_state(comment, hidden, triage_zammad_client) if comment
  end

  def sync_issue_state(comment, hidden, triage_zammad_client)
    issue = comment.issue
    new_state = hidden ? state_after_hiding(issue, comment) : state_after_showing(issue)
    return unless new_state

    triage_zammad_client.update_ticket!(issue.resolution_external_id || issue.triage_external_id, { "ops_state" => new_state })
  end

  def state_after_showing(issue)
    "in_progress" if issue.state&.key.in?(%w[sent_to_responsible unresolved])
  end

  def state_after_hiding(issue, comment)
    return unless issue.state&.key == "in_progress"
    return if other_visible_responsible_subject_comment?(issue, comment)

    "sent_to_responsible"
  end

  def other_visible_responsible_subject_comment?(issue, comment)
    issue.comments
      .where(type: Issues::ResponsibleSubjectComment.name, hidden: false)
      .where.not(id: comment.id)
      .exists?
  end
end
