class Connector::Legacy::ImportManualBackofficeAlertsActivityFromLegacyDbToBackofficeJob < ApplicationJob
  include ImportMethods

  def perform(tenant, legacy_issue_id, zammad_client: Connector::BackofficeZammadEnvironment.client(tenant))
    zammad_client.check_import_mode!

    Legacy::Alerts::Communication.where(alert: legacy_issue_id).find_in_batches do |group|
      group.each do |legacy_record|
        legacy_data = OpenStruct.new(
          id: legacy_record.id,
          author: Legacy::User.find_or_create_responsible_subjects_user(legacy_record.user),
          body: legacy_record.message,
          internal: legacy_record.internal,
          created_at: convert_timestamp_value(legacy_record.ts),
          attachments: Legacy::Alerts::CommunicationAttachment.where(communication_id: legacy_record.id).map do |legacy_attachment_record|
            OpenStruct.new(
              filename: legacy_attachment_record.name,
              mimetype: attachment_mimetype_by_name(legacy_attachment_record.name),
              content: download_from_ops_portal(legacy_attachment_record.path).read
            )
          end
        )

        backoffice_issue = tenant.issues.find_by(legacy_id: legacy_issue_id)

        raise unless backoffice_issue

        zammad_client.find_or_create_article_from_legacy_data!(
          legacy_data,
          backoffice_issue,
          uuid: "00000000-0000-0000-0000-#{legacy_data.id.to_s.rjust(12, "0")}",
          sender: "Agent"
        )
      end
    end
  end
end
