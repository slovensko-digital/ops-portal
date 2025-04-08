class Triage::CreateNewPortalActivityFromTriageJob < ApplicationJob
  OPS_PORTAL_ARTICLE_TAG = ENV.fetch("OPS_PORTAL_ARTICLE_TAG", "[[ops portal]]")

  def perform(ticket_id, article_id, triage_zammad_client: TriageZammadEnvironment.client)
    article = triage_zammad_client.get_article(ticket_id, article_id)
    raise "Article not found" unless article
    return unless article[:body].include? OPS_PORTAL_ARTICLE_TAG

    issue = Issue.find_by(triage_external_id: ticket_id)
    raise "Issue not found" unless issue

    # TODO: consider using other than the Issues::Comment model
    Issues::Comment.find_or_initialize_by(triage_external_id: article_id).tap do |comment|
      comment.text = article[:body]
      comment.activity ||= issue.comment_activities.create!
    end.save!
  end
end
