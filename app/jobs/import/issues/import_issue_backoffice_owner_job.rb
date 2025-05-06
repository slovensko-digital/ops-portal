module Import
  class Issues::ImportIssueBackofficeOwnerJob < ApplicationJob
    def perform(issue:)
      backoffice_owners = Legacy::Alerts::MunicipalityUser.where(alert_id: issue.legacy_id).order(:id)

      issue.legacy_data["backoffice_owner_legacy_id"] = backoffice_owners&.last&.municipality_user_id
      issue.legacy_data["other_backoffice_owners_legacy_ids"] = backoffice_owners[0..-2]&.map(&:municipality_user_id)

      issue.save!
    end
  end
end
