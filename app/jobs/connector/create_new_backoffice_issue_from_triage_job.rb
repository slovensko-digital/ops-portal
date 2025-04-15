class Connector::CreateNewBackofficeIssueFromTriageJob < ApplicationJob
  def perform(tenant, issue_id, zammad_api_client: Connector::ZammadApiClient, ops_api_client: Connector::OpsApiClient)
    ops_client = ops_api_client.new(tenant)
    zammad_client = zammad_api_client.new(tenant)

    issue_data = ops_client.get_issue(issue_id, include_customer_activities: tenant.receive_customer_activities?)
    zammad_client.create_issue!(issue_data)
  end
end
