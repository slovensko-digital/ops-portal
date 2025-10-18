class Connector::Legacy::MagistratSetGroupAndOwnersJob < ApplicationJob
  def perform(tenant, triage_issue_id, zammad_client: Connector::BackofficeZammadEnvironment.client(tenant))
    zammad_client.check_import_mode!

    issue = Issue.find_by(resolution_external_id: triage_issue_id)
    tenant_issue = tenant.issues.find_by(triage_external_id: triage_issue_id)

    group = find_or_create_zammad_group(issue, zammad_client)
    zammad_client.add_ticket_to_group(issue, group.name) if group

    backoffice_owner = [ ResponsibleSubjects::User.find_by(legacy_id: 714), ResponsibleSubjects::User.find_by(legacy_id: 1168) ].sample
    zammad_client.add_agent_to_group(backoffice_owner, group.name) if group
    zammad_client.set_ticket_owner_based_on_issue(issue, owner: backoffice_owner)

    backoffice_owner_zammad_id = zammad_client.create_or_find_agent(backoffice_owner)

    Legacy::Alerts::MunicipalityUser.where(alert_id: issue.id).find_each do |alert_municipality_user|
      subtask_owner = ResponsibleSubjects::User.find_by(legacy_id: alert_municipality_user.municipality_user_id)
      subtask_owner_zammad_id = zammad_client.create_or_find_agent(subtask_owner)

      zammad_client.add_user_to_group_read_only(subtask_owner_zammad_id, group.name) if group

      zammad_client.create_subtask(tenant_issue.backoffice_external_id, backoffice_owner_zammad_id, alert_municipality_user.municipality_user_id, issue.title, subtask_owner_zammad_id, use_parent_state: true)
    end
  end

  def find_or_create_zammad_group(issue, zammad_client)
    legacy_org_units = ResponsibleSubjects::OrganizationUnit.where(legacy_id: [ issue.legacy_data&.fetch("organizational_unit_id"), issue.legacy_data&.fetch("organization_unit_id2") ].compact)

    return unless legacy_org_units.any?

    selected_organization_unit = if issue.backoffice_owner&.organization_unit_id && legacy_org_units.where(id: issue.backoffice_owner.organization_unit_id).any?
      legacy_org_units.find(issue.backoffice_owner.organization_unit_id)
    else
      legacy_org_units.find_by(legacy_id: issue.legacy_data&.fetch("organizational_unit_id")).presence || legacy_org_units.find_by(legacy_id: issue.legacy_data&.fetch("organization_unit_id2"))
    end

    zammad_client.find_or_create_group(selected_organization_unit.name)
  end
end
