class Connector::Legacy::SetBackofficeTicketOwnerAndGroupJob < ApplicationJob
  def perform(tenant, triage_issue_id, zammad_client: Connector::BackofficeZammadEnvironment.client(tenant))
    zammad_client.check_import_mode!

    issue = Issue.find_by(resolution_external_id: triage_issue_id)

    set_group(issue, zammad_client)

    zammad_client.set_ticket_owner(issue)

    issue.legacy_data&.fetch("other_backoffice_owners_legacy_ids")&.each do |other_legacy_owner_id|
      backoffice_agent = Legacy::User.find_or_create_responsible_subjects_user(other_legacy_owner_id)
      zammad_client.subscribe_ticket(backoffice_agent, issue)
    end
  end

  private

  def set_group(issue, zammad_client)
    legacy_org_units = ResponsibleSubjects::OrganizationUnit.where(legacy_id: [ issue.legacy_data&.fetch("organizational_unit_id"), issue.legacy_data&.fetch("organization_unit_id2") ].compact)

    return unless legacy_org_units.any?

    selected_organization_unit = if issue.backoffice_owner&.organization_unit_id && legacy_org_units.where(id: issue.backoffice_owner.organization_unit_id).any?
      legacy_org_units.find(issue.backoffice_owner.organization_unit_id)
    else
      legacy_org_units.find_by(legacy_id: issue.legacy_data&.fetch("organizational_unit_id")).presence || legacy_org_units.find_by(legacy_id: issue.legacy_data&.fetch("organization_unit_id2"))
    end

    group = zammad_client.find_or_create_group(selected_organization_unit.name)
    zammad_client.add_ticket_to_group(issue, group.name)
    zammad_client.add_agent_to_group(issue.backoffice_owner, group.name) if issue.backoffice_owner

    issue.legacy_data&.fetch("other_backoffice_owners_legacy_ids")&.each do |other_legacy_owner_id|
      backoffice_agent = Legacy::User.find_or_create_responsible_subjects_user(other_legacy_owner_id)
      zammad_client.add_agent_to_group(backoffice_agent, group.name)
    end
  end
end
