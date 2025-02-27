module Import
  class Issues::ImportIssueUpdateAttachmentsJob < ApplicationJob
    include ImportMethods

    def perform(update:)
      Legacy::GenericModel.set_table_name("media_updates")
      Legacy::GenericModel.where(update_id: update.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          update.attachments.attach(io: download_from_ops_portal(legacy_record.href), filename: File.basename(legacy_record.href))
        end
      end
    end
  end
end
