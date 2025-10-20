class Connector::CreateNewBackofficeSubtaskJob < ApplicationJob
  def perform(tenant, ticket_id, author_id, number:, title:, user_id:, due_date:, zammad_api_client: Connector::BackofficeZammadEnvironment.client(tenant))
    zammad_api_client.create_subtask(ticket_id, author_id, number, title, user_id, due_date)
  end
end
