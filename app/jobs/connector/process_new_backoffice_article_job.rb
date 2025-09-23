class Connector::ProcessNewBackofficeArticleJob < ApplicationJob
  def perform(tenant, ticket_id, article_id, zammad_api_client: Connector::BackofficeZammadEnvironment.client(tenant), ops_api_client: Connector::OpsApiClient)
    return if tenant.activities.find_by(backoffice_external_id: article_id)&.triage_external_id

    article = zammad_api_client.get_article(ticket_id, article_id)
    if Connector::SubtaskParser.has_subtasks?(article&.body)
      Connector::CreateNewBackofficeSubtasksFromArticleJob.perform_later(tenant, ticket_id, article_id)
    elsif article.internal == false
      Connector::SendNewActivityToTriageFromBackofficeJob.perform_later(tenant, ticket_id, article_id)
    end
  end
end
