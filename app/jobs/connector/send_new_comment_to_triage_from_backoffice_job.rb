class Connector::SendNewCommentToTriageFromBackofficeJob < ApplicationJob
  def perform(ticket_id, article_id, zammad_api_client: Connector::ZammadApiClient, ops_api_client: Connector::OpsApiClient)
  end
end
