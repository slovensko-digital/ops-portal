class Connector::Legacy::ImportPrivateBackofficeIssuesToBackofficeJob < ApplicationJob
  include ImportMethods

  def perform(
    tenant,
    import_since: Date.parse("2020-01-01").beginning_of_day,
    zammad_api_client: Connector::ZammadApiClient,
    import_activities_job: Connector::Legacy::ImportPrivateBackofficeIssueActivityToBackofficeJob
  )
    zammad_client = zammad_api_client.new(tenant)
    zammad_client.check_import_mode!

    tenant_responsible_subject = ::Client.find(tenant.ops_api_subject_identifier).responsible_subject

    Legacy::Alert
      .where(is_manual: 1)
      .where(zodpovednost: tenant_responsible_subject.legacy_id)
      .where("posted_time >= ?", import_since.to_i).find_in_batches do |group|
      group.each do |legacy_record|
        subtype = ::Issues::Subtype.find_by(legacy_id: legacy_record.kategoria)
        subcategory = subtype&.subcategory || ::Issues::Subcategory.find_by(legacy_id: legacy_record.kategoria)
        category = subcategory&.category || ::Issues::Category.find_by(legacy_id: legacy_record.kategoria)

        legacy_data = OpenStruct.new(
          id: legacy_record.id,
          state: ::Issues::State.find_by(legacy_id: legacy_record.status),
          title: legacy_record.heading,
          description: legacy_record.description,
          author: nil,
          responsible_subject: tenant_responsible_subject,
          internal: legacy_record.is_manual,
          category: category,
          subcategory: subcategory,
          subtype: subtype,
          backoffice_owner: nil, # TODO set owner
          municipality: Municipality.find_by(legacy_id: legacy_record.mesto),
          municipality_district: MunicipalityDistrict.find_by(legacy_id: legacy_record.mestska_cast),
          address_street: Street.find_by(legacy_id: legacy_record.ulica)&.name,
          latitude: legacy_record.map_x,
          longitude: legacy_record.map_y,
          created_at: convert_timestamp_value(legacy_record.posted_time),
          attachments: Legacy::Alerts::Image.where(alert_id: legacy_record.id).order(:position).map do |legacy_attachment_record|
            OpenStruct.new(
              filename: File.basename(legacy_attachment_record.original),
              mimetype: attachment_mimetype_by_name(legacy_attachment_record.original),
              content: download_from_ops_portal(legacy_attachment_record.original)
            )
          end
        )

        zammad_client.find_or_create_ticket_from_legacy_record!(
          legacy_data,
          state: ISSUE_OPS_STATE_TO_BACKOFFICE_STATE.fetch(legacy_data.state.name),
          group: zammad_api_client::IMPORT_GROUP
        )

        import_activities_job.perform_later(tenant, legacy_record.id)
      end
    end
  end

  ISSUE_OPS_STATE_TO_BACKOFFICE_STATE = {
    "Čakajúci" => "new",
    "Zaslaný zodpovednému" => "open",
    "V riešení" => "open",
    "Odstúpený" => "open",
    "Označený za vyriešený" => "open",
    "Vyriešený" => "closed",
    "Uzavretý" => "closed",
    "Neriešený" => "closed",
    "Neprijatý" => "closed",
    "Zamietnutý" => "closed"
  }
end
