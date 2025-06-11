class Connector::Legacy::SetBackofficeTicketGroupJob < ApplicationJob
  def perform(tenant, triage_issue_id, zammad_client: Connector::BackofficeZammadEnvironment.client(tenant))
    zammad_client.check_import_mode!

    issue = Issue.find_by(resolution_external_id: triage_issue_id)

    legacy_org_units = ResponsibleSubjects::OrganizationUnit.where(legacy_id: [ issue.legacy_data&.fetch("organizational_unit_id"), issue.legacy_data&.fetch("organization_unit_id2") ].compact)

    return unless legacy_org_units.any?

    selected_organization_unit = if issue.backoffice_owner&.organization_unit_id && legacy_org_units.where(id: issue.backoffice_owner.organization_unit_id).any?
      legacy_org_units.find(issue.backoffice_owner.organization_unit_id)
    else
      legacy_org_units.find_by(legacy_id: issue.legacy_data&.fetch("organizational_unit_id")).presence || legacy_org_units.find_by(legacy_id: issue.legacy_data&.fetch("organization_unit_id2"))
    end

    group = zammad_client.find_or_create_group(selected_organization_unit.name)
    zammad_client.add_ticket_to_group(issue, group.name)
    zammad_client.add_ticket_owner_to_group(issue.backoffice_owner, group.name) if issue.backoffice_owner
  end
end
