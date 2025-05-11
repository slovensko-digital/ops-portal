class Triage::CreateNewPortalActivityFromTriageJob < ApplicationJob
  OPS_PORTAL_ARTICLE_TAG = TriageZammadEnvironment::OPS_PORTAL_ARTICLE_TAG

  def perform(ticket_id, article_id, triage_zammad_client: TriageZammadEnvironment.client)
    ticket = triage_zammad_client.get_ticket(ticket_id)
    raise "Ticket not found" unless ticket
    raise "Ticket is not a portal ticket" unless ticket[:origin] == "portal"

    allowed_article_types = [
      :agent_portal_comment,
      :agent_portal_and_backoffice_comment,
      :responsible_subject_portal_and_backoffice_comment,
      :agent_private_comment
    ]

    article = triage_zammad_client.get_article(ticket_id, article_id, allowed_article_types: allowed_article_types)
    raise "Article not found" unless article
    return if article[:customer_activity]

    process_type = ticket[:process_type]
    case process_type
    when "portal_issue_triage"
      issue = Issue.find_by!(triage_external_id: ticket_id)
      return if issue.comments.find_by(triage_external_id: article_id)

      Issues::AgentPrivateComment.create!(
        triage_external_id: article_id,
        text: article[:body],
        activity: issue.comment_activities.create!,
      )

    when "portal_issue_resolution"
      issue = Issue.find_by!(resolution_external_id: ticket_id)
      return if issue.comments.find_by(triage_external_id: article_id)

      if [ :responsible_subject_portal_and_backoffice_comment, :responsible_subject_portal_comment ].include?(article[:article_type])
        Issues::ResponsibleSubjectComment.create!(
          triage_external_id: article_id,
          text: article[:body],
          activity: issue.comment_activities.create!,
          responsible_subject_author: article[:author]
        )
      elsif [ :agent_portal_comment, :agent_portal_and_backoffice_comment ].include?(article[:article_type])
        Issues::AgentComment.create!(
          triage_external_id: article_id,
          text: article[:body],
          activity: issue.comment_activities.create!
        )
      end
    else
      # TODO add support for other process types
      raise "Process type not yet supported: #{process_type}"
    end
  end
end
