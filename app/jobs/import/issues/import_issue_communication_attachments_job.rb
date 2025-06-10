module Import
  class Issues::ImportIssueCommunicationAttachmentsJob < ApplicationJob
    queue_with_priority 100

    include ImportMethods

    def perform(communication:)
      Issue.transaction do
        communication.attachments.purge

        paths = Legacy::Alerts::CommunicationAttachment.where(communication_id: communication.legacy_id).pluck(:path).uniq
        communication.attachments.attach(download_attachables_from_ops_portal(paths))
      end
    end
  end
end
