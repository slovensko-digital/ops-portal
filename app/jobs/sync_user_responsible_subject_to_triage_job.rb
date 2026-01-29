class SyncUserResponsibleSubjectToTriageJob < ApplicationJob
  def perform(user, client: TriageZammadEnvironment.client)
    responsible_subject = user.responsible_subject
    responsible_subject.external_id = client.create_responsible_subject!(responsible_subject)
    responsible_subject.save!
  end
end
