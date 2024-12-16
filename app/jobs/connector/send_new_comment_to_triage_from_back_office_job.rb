class Connector::SendNewIssueStatusToTriageFromBackOfficeJob < ApplicationJob
  def perform(ticket_id, article_id, zammad_api_client: Connector::ZammadApiClient, ops_api_client: Connector::OpsApiClient)
    ticket = zammad_api_client.
  end
end
