module Import
  class Issues::ImportIssuePhotosJob < ApplicationJob
    include ImportHelper

    def perform(issue:)
      Legacy::GenericModel.set_table_name("media_images")
      Legacy::GenericModel.where(alert_id: issue.id).order(:position).find_in_batches do |group|
        group.each do |legacy_record|
          issue.photos.attach(io: download_from_ops_portal(legacy_record.original), filename: File.basename(legacy_record.original))
          issue.photos.order(:id).last.update(position: legacy_record.position)
        end
      end
    end
  end
end
