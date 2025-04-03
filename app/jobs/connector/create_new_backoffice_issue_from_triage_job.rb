class Connector::CreateNewBackofficeIssueFromTriageJob < ApplicationJob
  def perform(tenant, include_customer_articles, issue_id, zammad_api_client: Connector::ZammadApiClient, ops_api_client: Connector::OpsApiClient)
    ops_client = ops_api_client.new(tenant)
    zammad_client = zammad_api_client.new(tenant)

    issue_data = ops_client.get_issue issue_id, include_customer_articles: include_customer_articles
    zammad_client.create_issue! issue_data
  end
end
