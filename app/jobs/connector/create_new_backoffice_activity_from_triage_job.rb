class Connector::CreateNewBackofficeActivityFromTriageJob < ApplicationJob
  def perform(tenant, issue_id, activity_id, zammad_client: Connector::BackofficeZammadEnvironment.client(tenant), ops_api_client: Connector::OpsApiClient)
    return if tenant.activities.find_by(triage_external_id: activity_id).present?

    ops_client = ops_api_client.new(tenant)
    activity = ops_client.get_activity(issue_id, activity_id)
    raise "Activity not found" unless activity

    return unless tenant.receive_customer_activities? || activity["activity_type"].in?([ "agent_portal_and_backoffice_comment", "agent_backoffice_comment" ])

    begin
      zammad_client.create_activity!(issue_id, activity)
    rescue => e
      # it is OK that rejected issue is not found in BackOffice
      if e.message.include?("Issue not found")
        issue = ops_client.get_issue(issue_id, expand: false)
        return if issue["ops_state"] == "rejected"
      end

      raise e
    end
  end
end
