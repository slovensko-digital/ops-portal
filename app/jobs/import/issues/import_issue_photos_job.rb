module Import
  class Issues::ImportIssuePhotosJob < ApplicationJob
    include ImportMethods

    def perform(issue:)
      Legacy::GenericModel.set_table_name("media_images")
      Legacy::GenericModel.where(alert_id: issue.legacy_id).order(:position).find_in_batches do |group|
        group.each do |legacy_record|
          photo_content = download_from_ops_portal(legacy_record.original)
          photo_name = File.basename(legacy_record.original)

          persisted = issue.photos_attachments.includes(:blob).where(blob: { filename: photo_name, byte_size: photo_content.size }).any?

          unless persisted
            issue.photos.attach(io: photo_content, filename: photo_name)
            issue.photos.order(:id).last.update(position: legacy_record.position)
          end
        end
      end
    end
  end
end
