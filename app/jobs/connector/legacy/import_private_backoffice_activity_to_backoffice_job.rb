class Connector::Legacy::ImportPrivateBackofficeActivityToBackofficeJob < ApplicationJob
  include ImportMethods

  def perform(tenant, triage_issue_id, zammad_api_client: Connector::ZammadApiClient)
    zammad_client = zammad_api_client.new(tenant)
    zammad_client.check_import_mode!

    issue = Issue.find_by(triage_external_id: triage_issue_id)

    raise "Missing legacy ID" unless issue.legacy_id

    Legacy::Alerts::Communication.where(alert: issue.legacy_id).where(internal: 1).find_in_batches do |group|
      group.each do |legacy_record|
        legacy_data = OpenStruct.new(
          id: legacy_record.id,
          author: Legacy::User.find_or_create_responsible_subjects_user(legacy_record.user),
          body: legacy_record.message,
          created_at: convert_timestamp_value(legacy_record.ts),
          attachments: Legacy::Alerts::CommunicationAttachment.where(communication_id: legacy_record.id).map do |legacy_attachment_record|
            OpenStruct.new(
              filename: legacy_attachment_record.name,
              content: download_from_ops_portal(legacy_attachment_record.path)
            )
          end
        )

        zammad_client.find_or_create_article_from_legacy_record!(issue, legacy_data, internal: true, sender: "Agent")
      end
    end
  end
end
