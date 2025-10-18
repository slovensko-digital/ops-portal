class Connector::Legacy::MagistratSetGroupAndOwnersForManualTicketsJob < ApplicationJob
  def perform(tenant, legacy_alert_id, zammad_client: Connector::BackofficeZammadEnvironment.client(tenant))
    zammad_client.check_import_mode!

    legacy_record = Legacy::Alert.find(legacy_alert_id)
    tenant_issue = tenant.issues.find_by(legacy_id: legacy_alert_id)

    group = find_or_create_zammad_group(legacy_record, zammad_client)
    zammad_client.add_manual_ticket_to_group(tenant_issue, group.name) if group

    backoffice_owner = [ ResponsibleSubjects::User.find_by(legacy_id: 714), ResponsibleSubjects::User.find_by(legacy_id: 1168) ].sample
    zammad_client.add_agent_to_group(backoffice_owner, group.name) if group
    zammad_client.set_ticket_owner_based_on_tenant_issue(tenant_issue, owner: backoffice_owner)

    backoffice_owner_zammad_id = zammad_client.create_or_find_agent(backoffice_owner)

    Legacy::Alerts::MunicipalityUser.where(alert_id: legacy_alert_id).find_each do |alert_municipality_user|
      subtask_owner = ResponsibleSubjects::User.find_by(legacy_id: alert_municipality_user.municipality_user_id)
      subtask_owner_zammad_id = zammad_client.create_or_find_agent(subtask_owner)

      zammad_client.add_user_to_group_read_only(subtask_owner_zammad_id, group.name) if group

      zammad_client.create_subtask(tenant_issue.backoffice_external_id, backoffice_owner_zammad_id, alert_municipality_user.municipality_user_id, legacy_record.heading, subtask_owner_zammad_id, use_parent_state: true)
    end
  end

  def find_or_create_zammad_group(legacy_record, zammad_client)
    legacy_org_units = ResponsibleSubjects::OrganizationUnit.where(legacy_id: [ legacy_record.organizational_unit_id, legacy_record.organizational_unit_id2 ].compact)
    backoffice_owner_legacy_id = Legacy::Alerts::MunicipalityUser.where(alert_id: legacy_record.id).order(:id).last&.municipality_user_id
    backoffice_owner = ResponsibleSubjects::User.find_by(legacy_id: backoffice_owner_legacy_id)

    return unless legacy_org_units.any?

    selected_organization_unit = if backoffice_owner&.organization_unit_id && legacy_org_units.where(id: backoffice_owner.organization_unit_id).any?
      legacy_org_units.find(backoffice_owner.organization_unit_id)
    else
      legacy_org_units.find_by(legacy_id: legacy_record.organizational_unit_id).presence || legacy_org_units.find_by(legacy_id: legacy_record.organizational_unit_id2)
    end

    zammad_client.find_or_create_group(selected_organization_unit.name)
  end
end
