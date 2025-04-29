class Connector::SetBackofficeTicketOwnerJob < ApplicationJob
  def perform(tenant, triage_issue_id, zammad_api_client: Connector::ZammadApiClient)
    zammad_client = zammad_api_client.new(tenant)
    zammad_client.check_import_mode!

    issue = Issue.find_by(triage_external_id: triage_issue_id)

    zammad_client.set_ticket_owner(issue)
  end
end
