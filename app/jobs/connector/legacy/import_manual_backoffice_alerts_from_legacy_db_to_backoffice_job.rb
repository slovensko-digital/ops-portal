class Connector::Legacy::ImportManualBackofficeAlertsFromLegacyDbToBackofficeJob < ApplicationJob
  def perform(
    tenant,
    import_since: Date.parse("2020-01-01").beginning_of_day,
    import_alert_job: Connector::Legacy::ImportManualBackofficeAlertFromLegacyDbToBackofficeJob
  )
    tenant_responsible_subject = ::Client.find(tenant.ops_api_subject_identifier).responsible_subject

    Legacy::Alert
      .where(is_manual: 1)
      .where(zodpovednost: tenant_responsible_subject.legacy_id)
      .where("posted_time >= ?", import_since.to_i).find_in_batches do |group|
      group.each do |legacy_record|
        import_alert_job.perform_later(tenant, legacy_record)
      end
    end
  end
end
