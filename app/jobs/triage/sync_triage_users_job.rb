class Triage::SyncTriageUsersJob < ApplicationJob
  def perform(client: TriageZammadEnvironment.client)
    client.get_users.each do |u|
      user = User.find_or_initialize_by(zammad_identifier: u.id)
      next unless user.new_record?
      user.update(email: u.email, firstname: u.firstname, lastname: u.lastname)
      user.save!
    end
  end
end
