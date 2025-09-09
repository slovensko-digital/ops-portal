module TriageUtils
  def self.get_issue_from_ticket(ticket)
    case ticket[:process_type]
    when "portal_issue_triage"
      Issue.find_by!(triage_external_id: ticket[:triage_identifier])
    when "portal_issue_resolution"
      Issue.find_by!(resolution_external_id: ticket[:triage_identifier])
    else
      raise "Invalid process type"
    end
  end
end
