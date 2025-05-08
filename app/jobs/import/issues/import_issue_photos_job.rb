module Import
  class Issues::ImportIssuePhotosJob < ApplicationJob
    include ImportMethods

    def perform(issue:, import_photo_job: Issues::ImportIssuePhotoJob)
      Legacy::Alerts::Image.where(alert_id: issue.legacy_id).order(:position).find_in_batches do |group|
        group.each do |legacy_record|
          import_photo_job.perform_later(legacy_record, issue: issue)
        end
      end
    end
  end
end
