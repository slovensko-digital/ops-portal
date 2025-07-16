class Triage::CloseIssueUpdateTriageTicketJob < ApplicationJob
  def perform(issue_update, state, triage_zammad_client: TriageZammadEnvironment.client)
    triage_zammad_client.close_ticket!(issue_update.external_id)

    # Create internal system note
    human_text = case state
    when "rejected"
      "zamietnutá"
    when "accepted"
      "prijatá"
    end
    triage_zammad_client.create_internal_system_note!(
      issue_update.external_id,
      "Aktualizácia podnetu bola #{human_text}."
    )
  end
end
