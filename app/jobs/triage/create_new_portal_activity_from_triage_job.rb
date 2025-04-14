class Triage::CreateNewPortalActivityFromTriageJob < ApplicationJob
  OPS_PORTAL_ARTICLE_TAG = ENV.fetch("OPS_PORTAL_ARTICLE_TAG", "[[ops portal]]")

  def perform(ticket_id, article_id, triage_zammad_client: TriageZammadEnvironment.client)
    ticket = triage_zammad_client.get_ticket(ticket_id)
    raise "Ticket not found" unless ticket
    raise "Ticket is not a portal ticket" unless ticket[:origin] == "portal"

    article = triage_zammad_client.get_article(ticket_id, article_id)
    raise "Article not found" unless article

    process_type = ticket[:process_type]
    case process_type
    when "portal_issue_triage"
      issue = Issue.find_by!(triage_external_id: ticket_id)

      # TODO: consider using other than the Issues::Comment model
      Issues::Comment.find_or_initialize_by(triage_external_id: article_id).tap do |comment|
        comment.text = article[:body]
        comment.activity ||= issue.comment_activities.create!
      end.save!

    when "portal_issue_resolution"
      issue = Issue.find_by!(resolution_external_id: ticket_id)

      # TODO: consider using other than the Issues::Comment model
      Issues::Comment.find_or_initialize_by(triage_external_id: article_id).tap do |comment|
        comment.text = article[:body]
        comment.activity ||= issue.comment_activities.create!
      end.save!
    else
      # TODO add support for other process types
      raise "Process type not yet supported: #{process_type}"
    end
  end
end
