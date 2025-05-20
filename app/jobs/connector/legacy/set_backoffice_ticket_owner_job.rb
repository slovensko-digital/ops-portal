class Connector::Legacy::SetBackofficeTicketOwnerJob < ApplicationJob
  def perform(tenant, triage_issue_id, zammad_client: Connector::BackofficeZammadEnvironment.client(tenant))
    zammad_client.check_import_mode!

    issue = Issue.find_by(resolution_external_id: triage_issue_id)

    zammad_client.set_ticket_owner(issue)

    issue.legacy_data&.fetch("other_backoffice_owners_legacy_ids")&.each do |other_legacy_owner_id|
      backoffice_agent = Legacy::User.find_or_create_responsible_subjects_user(other_legacy_owner_id)
      zammad_client.subscribe_ticket(backoffice_agent, issue)
    end
  end
end
