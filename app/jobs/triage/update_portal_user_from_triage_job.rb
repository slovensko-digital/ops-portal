class Triage::UpdatePortalUserFromTriageJob < ApplicationJob
  def perform(user_id, triage_zammad_client: TriageZammadEnvironment.client)
    triage_user = triage_zammad_client.find_user(user_id)
    return unless triage_user

    user = User.find_by!(external_id: triage_user.id.to_i)
    return unless user

    user.update!(banned: triage_user.banned) unless triage_user.banned == user.banned
  end
end
