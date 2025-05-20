class Connector::UpdateBackofficeIssueFromTriageJob < ApplicationJob
  def perform(tenant, issue_id, zammad_environment: Connector::BackofficeZammadEnvironment, ops_api_client: Connector::OpsApiClient)
    ops_client = ops_api_client.new(tenant)
    zammad_client = zammad_environment.client(tenant)

    issue_data = ops_client.get_issue issue_id
    zammad_client.update_issue! issue_id, issue_data
  end
end
