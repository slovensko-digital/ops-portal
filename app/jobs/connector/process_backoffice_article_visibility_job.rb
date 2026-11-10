class Connector::ProcessBackofficeArticleVisibilityJob < ApplicationJob
  VISIBILITY_WINDOW = 24.hours

  def perform(tenant, ticket_id, article_id, updated_by_admin = false, backoffice_client: Connector::BackofficeZammadEnvironment.client(tenant), triage_client: TriageZammadEnvironment.client)
    article = backoffice_client.get_article(ticket_id, article_id)
    return unless article
    # support (admins) may toggle visibility after the window; their change
    # still has to propagate, otherwise backoffice and portal diverge.
    return unless updated_by_admin || within_visibility_window?(article)

    # internal articles created in backoffice have no activity mapping yet
    # (nothing is sent to triage until they become public), so the mapping
    # cannot gate the whole job.
    activity = tenant.activities.find_by(backoffice_external_id: article_id.to_i)

    if article.internal == true
      hide_in_triage(activity, triage_client) if activity&.triage_external_id
    elsif article.internal == false
      if activity&.triage_external_id
        show_in_triage(activity, triage_client)
      elsif tenant.issues.exists?(backoffice_external_id: ticket_id)
        Connector::SendNewActivityToTriageFromBackofficeJob.perform_later(tenant, ticket_id, article_id)
      end
    end
  end

  private

  # the window is measured from the backoffice article, not from when the
  # portal job runs, so a delayed webhook cannot extend or shorten it.
  # the boundary matches the backoffice guard (allowed while
  # created_at + 24h >= now).
  def within_visibility_window?(article)
    return false unless article.created_at

    toggle_time = article.updated_at || Time.current
    toggle_time <= article.created_at + VISIBILITY_WINDOW
  end

  # triage owns the article visibility: flipping it there lets the existing
  # triage -> portal sync hide the portal comment, instead of the portal
  # and triage copies diverging.
  def hide_in_triage(activity, triage_client)
    triage_client.update_article_internal!(activity.triage_external_id, true)
    revert_issue_state(activity, triage_client)
  end

  def show_in_triage(activity, triage_client)
    triage_client.update_article_internal!(activity.triage_external_id, false)
    advance_issue_state(activity, triage_client)
  end

  def portal_comment(activity)
    comment = Issues::Comment.find_by(triage_external_id: activity.triage_external_id)
    comment if comment.is_a?(Issues::ResponsibleSubjectComment)
  end

  def triage_ticket_id(comment)
    comment.issue.resolution_external_id || comment.issue.triage_external_id
  end

  # hiding the only visible responsible subject comment withdraws the
  # response, so the issue goes back to waiting for the responsible subject.
  # any other state, or another visible comment, leaves the state alone.
  def revert_issue_state(activity, triage_client)
    comment = portal_comment(activity)
    return unless comment
    return unless comment.issue.state&.key == "in_progress"
    return unless only_visible_responsible_subject_comment?(comment)

    triage_client.update_ticket!(triage_ticket_id(comment), { "ops_state" => "sent_to_responsible" })
  end

  # publishing a comment is a response, mirroring the triage trigger that
  # moves the issue to in progress when a public comment is created.
  def advance_issue_state(activity, triage_client)
    comment = portal_comment(activity)
    return unless comment
    return unless comment.issue.state&.key.in?(%w[sent_to_responsible unresolved])

    triage_client.update_ticket!(triage_ticket_id(comment), { "ops_state" => "in_progress" })
  end

  def only_visible_responsible_subject_comment?(comment)
    visible = comment.issue.comments.select do |other|
      other.is_a?(Issues::ResponsibleSubjectComment) && other.visible?
    end

    visible == [ comment ]
  end
end
