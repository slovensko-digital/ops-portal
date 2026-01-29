class SyncUserResponsibleSubjectToTriageJob < ApplicationJob
  def perform(user, client: TriageZammadEnvironment.client)
    external_id = client.create_responsible_subject!(responsible_subject)

    user.update!(external_id: external_id)
    user.responsible_subject.update!(external_id: external_id)
  end
end
