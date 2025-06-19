class Connector::Legacy::SetManualBackofficeTicketGroupJob < ApplicationJob
  def perform(tenant, legacy_alert_id, zammad_client: Connector::BackofficeZammadEnvironment.client(tenant))
    zammad_client.check_import_mode!

    legacy_record = Legacy::Alert.find(legacy_alert_id)
    tenant_issue = tenant.issues.find_by(legacy_id: legacy_alert_id)

    legacy_org_units = ResponsibleSubjects::OrganizationUnit.where(legacy_id: [ legacy_record.organizational_unit_id, legacy_record.organizational_unit_id2 ].compact)
    backoffice_owner_legacy_id = Legacy::Alerts::MunicipalityUser.where(alert_id: legacy_record.id).order(:id).last&.municipality_user_id
    backoffice_owner = ResponsibleSubjects::User.find_by(legacy_id: backoffice_owner_legacy_id)

    return unless legacy_org_units.any?

    selected_organization_unit = if backoffice_owner&.organization_unit_id && legacy_org_units.where(id: backoffice_owner.organization_unit_id).any?
      legacy_org_units.find(backoffice_owner.organization_unit_id)
    else
      legacy_org_units.find_by(legacy_id: legacy_record.organizational_unit_id).presence || legacy_org_units.find_by(legacy_id: legacy_record.organizational_unit_id2)
    end
    group = zammad_client.find_or_create_group(selected_organization_unit.name)

    zammad_client.add_agent_to_group(backoffice_owner, group.name) if backoffice_owner
    zammad_client.add_manual_ticket_to_group(tenant_issue, group.name)
  end
end
