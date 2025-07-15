class Triage::UpdatePortalIssueUpdateFromTriageJob < ApplicationJob
  def perform(ticket)
    issue_update = Issues::Update.find_by!(external_id: ticket[:triage_identifier])
    issue_update.update!(text: ticket[:description])

    case ticket[:ops_state_key]
    when "rejected"
      issue_update.update!(confirmed: false, published: false)
      Triage::CloseIssueUpdateTriageTicketJob.perform_later(issue_update, ticket[:ops_state_key])
    when "accepted"
      issue_update.update!(confirmed: true, published: true)
      Triage::CloseIssueUpdateTriageTicketJob.perform_later(issue_update, ticket[:ops_state_key])
    end

    ::SyncIssueActivityObjectToTriageJob.perform_later(issue: issue_update.issue, activity_object: issue_update, triage_group: ticket[:triage_group])
  end
end
