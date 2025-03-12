class Connector::UpdateBackofficeIssueStatusFromTriageJob < ApplicationJob
  def perform(tenant, issue_id, zammad_api_client: Connector::ZammadApiClient, ops_api_client: Connector::OpsApiClient)
    ops_client = ops_api_client.new(tenant)
    zammad_client = zammad_api_client.new(tenant)

    issue_state = ops_client.get_issue_state issue_id
    zammad_client.update_issue_status! issue_id, issue_state
  end
end
