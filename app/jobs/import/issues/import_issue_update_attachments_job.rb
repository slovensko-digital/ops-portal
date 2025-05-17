module Import
  class Issues::ImportIssueUpdateAttachmentsJob < ApplicationJob
    queue_with_priority 100

    include ImportMethods

    def perform(update:)
      Issue.transaction do
        hrefs = Legacy::Alerts::UpdateImage.where(update_id: update.legacy_id).pluck(:href)
        update.attachments.attach(download_attachables_from_ops_portal(hrefs))
      end
    end
  end
end
