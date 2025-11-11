class Triage::UpdatePortalIssueUpdateFromTriageJob < ApplicationJob
  def perform(ticket)
    issue_update = Issues::Update.find_by!(external_id: ticket[:triage_identifier])
    issue_update.update!(text: ticket[:description], resolves_issue: ticket[:issue_resolved] == "yes")

    case ticket[:ops_state_key]
    when "rejected"
      issue_update.update!(confirmed: false, verification_status: :rejected, published: false)

      issue = issue_update.issue
      if ticket[:issue_resolved] == "yes" && issue.resolved? && !issue.archived?
        issue.update!(state: Issues::State.find_by!(key: "in_progress"))
      end

      Triage::CloseIssueUpdateTriageTicketJob.perform_later(issue_update, ticket[:ops_state_key])
    when "accepted"
      issue_update.update!(confirmed: true, verification_status: :approved, published: true)

      if ticket[:issue_resolved]
        issue = issue_update.issue
        if ticket[:issue_resolved] == "yes" && !issue.resolved? && !issue.archived? && !issue.duplicate?
          issue.update!(state: Issues::State.find_by!(key: "resolved"))
          ::SyncIssueToTriageJob.perform_later(issue)
        elsif ticket[:issue_resolved] == "no" && issue.resolved? && !issue.archived?
          issue.update!(state: Issues::State.find_by!(key: "in_progress"))
        end
      end

      Triage::CloseIssueUpdateTriageTicketJob.perform_later(issue_update, ticket[:ops_state_key])
    end

    ::SyncIssueActivityObjectToTriageJob.perform_later(issue: issue_update.issue, activity_object: issue_update, triage_group: ticket[:triage_group])
  end
end
