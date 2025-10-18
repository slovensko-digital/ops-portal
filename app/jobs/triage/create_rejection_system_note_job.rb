class Triage::CreateRejectionSystemNoteJob < ApplicationJob
  def perform(issue, triage_zammad_client: TriageZammadEnvironment.client)
    triage_zammad_client.create_system_note!(
      issue.triage_external_id,
      "Triáž podnetu bola ukončená. Podnet bol zamietnutý."
    )
  end
end
