class Connector::UpdateBackofficeIssueFromTriageJob < ApplicationJob
  def perform(tenant, issue_id, zammad_client: Connector::BackofficeZammadEnvironment.client(tenant), ops_api_client: Connector::OpsApiClient)
    ops_client = ops_api_client.new(tenant)

    issue_data = ops_client.get_issue(issue_id)
    raise "Issue not found" unless issue_data

    begin
      zammad_client.update_issue!(issue_id, issue_data)
    rescue => e
      # it is OK that rejected issue is not found in BackOffice
      return if e.message.include?("Issue not found") && issue_data["ops_state"] == "rejected"
      raise e
    end
  end
end
