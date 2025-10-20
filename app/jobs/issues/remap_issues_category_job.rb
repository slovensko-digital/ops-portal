class Issues::RemapIssuesCategoryJob < ApplicationJob
  queue_as :default

  def perform
    Issue.transaction do
      Issue.where.not(legacy_id: nil).find_each do |issue|
        next unless issue.category&.legacy_id.present?

        RemapIssueCategoryJob.perform_later(issue)
      end
    end
  end
end
