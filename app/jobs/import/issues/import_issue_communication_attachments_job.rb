module Import
  class Issues::ImportIssueCommunicationAttachmentsJob < ApplicationJob
    include ImportMethods

    def perform(communication:)
      Legacy::GenericModel.set_table_name("communication_attachments")
      Legacy::GenericModel.where(communication_id: communication.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          communication.attachments.attach(io: download_from_ops_portal(legacy_record.path), filename: legacy_record.name)
        end
      end
    end
  end
end
