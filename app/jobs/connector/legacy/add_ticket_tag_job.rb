class Connector::Legacy::AddTicketTagJob < ApplicationJob
  def perform(tenant, triage_issue_id, zammad_client: Connector::BackofficeZammadEnvironment.client(tenant))
    return unless tenant.migrate_legacy_labels?

    zammad_client.check_import_mode!

    issue = Issue.find_by(resolution_external_id: triage_issue_id)

    return unless issue.legacy_data&.fetch("label_id")

    label = Legacy::Label.find_or_create_by_legacy_id(issue.legacy_data["label_id"])

    zammad_client.add_ticket_tag(issue, label.name)
  end
end
