module Import
  class Issues::ImportIssuePhotosJob < ApplicationJob
    queue_with_priority 100

    include ImportMethods

    def perform(issue:)
      Issue.transaction do
        issue.photos.purge

        paths = Legacy::Alerts::Image.where(alert_id: issue.legacy_id).order(:position).pluck(:original).uniq
        issue.photos.attach(download_attachables_from_ops_portal(paths))
      end
    end
  end
end
