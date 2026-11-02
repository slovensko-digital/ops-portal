# The Triage organization of a BASIC municipality shared by BasicActivation and ProDowngrade: the organization named
# after the municipality and its users, each also a User::ResponsibleSubject in the portal. Triage notifies the
# organization's users with role Externý zodpovedný subjekt about the municipality's tickets (it finds them by the
# organization named after the ticket's responsible subject), the first of the users gets it, the others are
# customers replying to issues.
#
# Expects name, user_emails and @client (ZammadApiClient with an admin token).
module ResponsibleSubjects::OrganizationSetup
  CUSTOMER_ROLE = "Customer"
  EXTERNAL_RESPONSIBLE_SUBJECT_ROLE = "Externý zodpovedný subjekt"

  # the responsible subject's email, the first user
  def email
    user_emails.first
  end

  def roles_for(user_email)
    user_email == email ? [ EXTERNAL_RESPONSIBLE_SUBJECT_ROLE ] : [ CUSTOMER_ROLE ]
  end

  # meno.priezvisko@obec.sk is Meno Priezvisko, any other address is <local part> <municipality name>
  def names_from_email(user_email)
    parts = user_email.split("@").first.split(".")
    return { firstname: parts.first.capitalize, lastname: parts.last.capitalize } if parts.size == 2 && parts.all?(&:present?)

    { firstname: user_email.split("@").first, lastname: name }
  end

  private

  def parse_user_emails(user_emails)
    Array(user_emails).flat_map { _1.to_s.split(",") }.map(&:strip).compact_blank
  end

  def user_emails_errors
    errors = []
    errors << "USERS is missing" if user_emails.empty?
    user_emails.reject { |address| address.match?(URI::MailTo::EMAIL_REGEXP) }.each do |address|
      errors << "#{address} is not a valid email address"
    end
    errors << "USERS contains duplicate emails" if user_emails.map(&:downcase).uniq.size < user_emails.size
    errors
  end

  def organization_role_errors
    [ CUSTOMER_ROLE, EXTERNAL_RESPONSIBLE_SUBJECT_ROLE ].reject { @client.find_role_by_name(_1) }.map { "Triage role #{_1} does not exist" }
  end

  # creates the organization and its users, a Triage user found by email (e.g. left by ProUpgrade) joins it instead,
  # keeping its other roles
  def create_organization_with_users!(existing_users: {})
    organization_id = @client.create_organization!(name)
    @log.call("Triage: organization #{organization_id}")

    user_emails.each do |user_email|
      roles = roles_for(user_email)
      if (user = existing_users[user_email])
        roles = (Array(user.roles) - [ CUSTOMER_ROLE, EXTERNAL_RESPONSIBLE_SUBJECT_ROLE ]) + roles
        @client.update_user!(user.id, organization_id: organization_id, roles: roles)
        user_id = user.id
      else
        user_id = @client.create_user!(email: user_email, organization: name, roles: roles, **names_from_email(user_email))
      end
      Triage::UpdatePortalUserFromTriageJob.perform_now(user_id, triage_zammad_client: @client)
      @log.call("Triage and portal: user #{user_email} (#{user_id}), #{roles.join(", ")}#{" (existing)" if user}")
    end
  end
end
