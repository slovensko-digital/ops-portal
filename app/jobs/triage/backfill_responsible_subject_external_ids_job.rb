module Triage
  # One-off: creates the Triage Zammad user for active responsible subjects that never synced to Triage.
  # Run with Triage::BackfillResponsibleSubjectExternalIdsJob.perform_later; safe to re-run.
  class BackfillResponsibleSubjectExternalIdsJob < ApplicationJob
    def perform(client: TriageZammadEnvironment.client)
      ResponsibleSubject.active.where(external_id: nil).find_each do |responsible_subject|
        responsible_subject.update!(external_id: client.create_responsible_subject!(responsible_subject))
      rescue StandardError => e
        Rails.logger.error("Backfilling external_id for responsible subject #{responsible_subject.id} failed: #{e.message}")
      end
    end
  end
end
