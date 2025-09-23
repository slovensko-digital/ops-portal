class Connector::CreateNewBackofficeSubtasksFromArticleJob < ApplicationJob
  def perform(tenant, ticket_id, article_id, zammad_api_client: Connector::BackofficeZammadEnvironment.client(tenant), ops_api_client: Connector::OpsApiClient)
    article = zammad_api_client.get_article(ticket_id, article_id)
    return unless article

    subtasks = Connector::SubtaskParser.parse_subtasks(article.body)

    subtasks.each_with_index do |subtask_data, index|
      identifier = "#{article_id}-#{index + 1}"

      Connector::CreateNewBackofficeSubtaskJob.perform_later(
        tenant,
        ticket_id,
        article.created_by_id,
        number: identifier,
        title: subtask_data.title,
        user_id: subtask_data.user_id,
        due_date: subtask_data.due_date
      )
    end
  end
end
