class ImportMunicipalityIssuesToTriageJob < ApplicationJob
  def perform(municipality:, municipality_district:, api: TriageZammadEnvironment.api, client: TriageZammadEnvironment.client, import_issue_to_triage_job: ImportIssueToTriageJob)
    api.check_import_mode!

    zammad_group = client.get_groups.select { |group| municipality.name.in?(group.name) && municipality_district&.name&.in?(group.name) }[0]
    raise "No zammad group found!" unless zammad_group

    Issue.where(municipality: municipality).where(municipality_district: municipality_district).find_in_batches do |group|
      group.each do |issue|
        import_issue_to_triage_job.perform_later(issue, zammad_group: zammad_group.name)
      end
    end
  end
end
