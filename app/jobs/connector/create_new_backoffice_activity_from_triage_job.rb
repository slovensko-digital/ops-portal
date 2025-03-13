class Connector::CreateNewBackofficeActivityFromTriageJob < ApplicationJob
  def perform(tenant, issue_id, activity_id, zammad_api_client: Connector::ZammadApiClient, ops_api_client: Connector::OpsApiClient)
    return if tenant.activities.find_by(triage_external_id: activity_id).present?

    ops_client = ops_api_client.new(tenant)
    zammad_client = zammad_api_client.new(tenant)

    activity = ops_client.get_activity(issue_id, activity_id)
    raise "Activity not found" unless activity
    zammad_client.create_activity!(issue_id, activity)
  end
end
