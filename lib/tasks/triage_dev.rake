namespace :triage do
  namespace :dev do
    desc "Push waiting issues (with their authors and comments) missing in the local Triage, safe to run repeatedly"
    task sync: :environment do
      abort "triage:dev:sync runs only in development" unless Rails.env.development?

      triage_host = URI(ENV.fetch("TRIAGE_ZAMMAD_URL")).host
      unless triage_host.in?(%w[localhost 127.0.0.1 host.docker.internal])
        abort "TRIAGE_ZAMMAD_URL points to #{triage_host}, triage:dev:sync only talks to a local Triage"
      end

      client = TriageZammadEnvironment.client

      # Links to a previous Triage (shared dev, or a local one that was reset) are stale, so every
      # citizen is linked again to the Triage user with its login, or left for the sync job to create.
      # The client cannot do it itself yet, see slovensko-digital/ops#1306.
      link_citizen = lambda do |user|
        next unless user.is_a?(User::Citizen)

        login = "ops-user-#{user.id}"
        match = client.raw_api_request(:get, "users/search?query=#{login}&limit=100").find { |u| u["login"] == login }
        user.update_columns(external_id: match&.dig("id"))
      end

      issues = Issue.joins(:state).where(issues_states: { key: "waiting" }, resolution_external_id: nil)
      synced = linked = failed = 0

      issues.find_each do |issue|
        next if issue.archived?

        # Zammad does not report a duplicate ticket number as such, so look the ticket up before creating it
        # (unquoted query, local Triage runs without Elasticsearch), see slovensko-digital/ops#1310
        number = "T-#{issue.id.to_s.rjust(4, '0')}"
        ticket = client.client.ticket.search(query: number).find { |t| t.number == number }

        if ticket
          issue.update_columns(triage_external_id: ticket.id)
          linked += 1
          puts "Issue ##{issue.id} already in Triage as ticket #{ticket.id}"
          next
        end

        activity_objects = issue.activities.includes(:activity_object).filter_map(&:activity_object)
        ([ issue.author ] + activity_objects.map { |o| o.try(:author) }).compact.uniq.each(&link_citizen)

        # ids pointing to a previous Triage are stale
        issue.update_columns(triage_external_id: nil)
        activity_objects.each { |o| o.update_columns(triage_external_id: nil) if o.respond_to?(:triage_external_id) }

        # perform directly (not perform_now) so errors surface here instead of becoming GoodJob retries
        SyncIssueToTriageJob.new.perform(issue, sync_activities: false)
        SyncIssueActivitiesToTriageJob.new.perform(issue, triage_group: nil)

        synced += 1
        puts "Issue ##{issue.id} -> Triage ticket #{issue.reload.triage_external_id}"
      rescue StandardError => e
        failed += 1
        puts "Issue ##{issue.id} failed: #{e.class}: #{e.message}"
      end

      puts "#{ENV.fetch('TRIAGE_ZAMMAD_URL')}: #{synced} issues synced, #{linked} already there, #{failed} failed"
    end
  end
end
