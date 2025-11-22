class Triage::CloseIssueUpdateTriageTicketJob < ApplicationJob
  def perform(issue_update, state, triage_zammad_client: TriageZammadEnvironment.client)
    triage_zammad_client.close_ticket!(issue_update.external_id)

    label = issue_update.resolves_issue? ? "Overenie" : "Aktualizácia"
    feminine = !issue_update.resolves_issue?

    # Create internal system note
    verb = feminine ? "bola" : "bolo"
    human_text = case state
    when "rejected"
      feminine ? "zamietnutá" : "zamietnuté"
    when "accepted"
      feminine ? "prijatá" : "prijaté"
    end

    triage_zammad_client.create_system_note!(
      issue_update.external_id,
      "#{label} podnetu #{verb} #{human_text}."
    )
  end
end
