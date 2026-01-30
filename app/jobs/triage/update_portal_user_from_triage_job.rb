class Triage::UpdatePortalUserFromTriageJob < ApplicationJob
  def perform(user_id, triage_zammad_client: TriageZammadEnvironment.client)
    triage_user = triage_zammad_client.find_user(user_id)
    return unless triage_user

    if triage_user.roles.include?("Zodpovedný Subjekt") && !User.exists?(external_id: triage_user.id.to_i)
      rs = ResponsibleSubject.find_by!(external_id: triage_user.id.to_i)

      User::ResponsibleSubject.create!(
        firstname: triage_user.firstname,
        lastname: triage_user.lastname,
        email: triage_user.email,
        external_id: triage_user.id.to_i,
        responsible_subject: rs,
        status: :verified,
        onboarded: true,
        password: SecureRandom.hex(32),
        phone_verified: true
      )
    end

    return unless triage_user.origin == "portal"

    user = User.find_by!(external_id: triage_user.id.to_i)
    user.update!(banned: triage_user.banned) unless triage_user.banned == user.banned
  end
end
