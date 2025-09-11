namespace :data do
  desc "Backfill issues.resolution_started_at based on resolution ticket creation"
  task backfill_resolution_started_at: :environment do
    client = TriageZammadEnvironment.client

    Issue.where(resolution_started_at: nil).find_each do |issue|
      next unless issue.resolution_external_id

      begin
        ts = client.get_ticket(issue.resolution_external_id)&.dig(:created_at)
        ts = ts.is_a?(String) ? Time.zone.parse(ts) : ts&.in_time_zone
        issue.update_columns(resolution_started_at: ts) if ts
      rescue => e
        warn "Issue ##{issue.id} failed: #{e.message}"
      end
    end
  end
end
