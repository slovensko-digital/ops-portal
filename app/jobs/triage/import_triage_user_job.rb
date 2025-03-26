class Triage::ImportTriageUserJob < ApplicationJob
  def perform(triage_user_id, client: TriageZammadEnvironment.client)
    u = client.get_user(triage_user_id)

    user = User.find_or_initialize_by(external_id: u.id)
    return unless user.new_record?
    user.update!(email: u.email, firstname: u.firstname, lastname: u.lastname)
  end
end
