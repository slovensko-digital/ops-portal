class Connector::Legacy::AddTicketTagJob < ApplicationJob
  def perform(tenant, triage_issue_id, zammad_client: Connector::BackofficeZammadEnvironment.client(tenant))
    zammad_client.check_import_mode!

    issue = Issue.find_by(resolution_external_id: triage_issue_id)

    return unless issue.legacy_data&.fetch("label_id")

    label = Legacy::Label.find_by(legacy_id: issue.legacy_data["label_id"])

    zammad_client.add_ticket_tag(issue, label.name)
  end
end
