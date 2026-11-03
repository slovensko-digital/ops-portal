# Activates a new municipality as a BASIC (pro: false) responsible subject in the portal and in Triage.
#
# validate! checks everything up front and raises Invalid with all problems found, nothing is created
# when anything is wrong. call then creates, in order:
#   - portal: the municipality at the boundary in its district (kraj) and its responsible subject, both inactive, the responsible
#     subject's email is the first user's,
#   - Triage: the responsible subject user, a group for the agent and an organization for the users, both
#     named after the municipality, the 700 trigger assigning portal tickets from the municipality to the agent,
#   - Triage: the users of the organization, each also created as User::ResponsibleSubject in the portal,
#     the first one is notified about the municipality's tickets as the external responsible subject
#     (Triage finds the recipients by the organization named after the ticket's responsible subject),
#     the others are customers replying to issues,
#   - portal: activates the municipality and the responsible subject.
# Triage changes cannot be rolled back, a failure in the middle leaves the steps already done in place.
#
# use_existing_municipality: true, for local development only, activates the inactive municipality and responsible
# subject named NAME that the dev seeds create instead of creating them, see ResponsibleSubjects::MunicipalitySetup.
# The municipality's issues stay only in the portal, they are not sent to Triage.
class ResponsibleSubjects::BasicActivation
  include ResponsibleSubjects::MunicipalitySetup
  include ResponsibleSubjects::OrganizationSetup
  include ResponsibleSubjects::TriageSetup

  class Invalid < StandardError; end

  attr_reader :name, :district_name, :user_emails, :triage_agent_email

  def initialize(boundary_id:, name:, district_name:, user_emails:, triage_agent_email:, client:, use_existing_municipality: false, log: ->(_message) { })
    @use_existing_municipality = use_existing_municipality
    @boundary_id = boundary_id
    @name = name.to_s.strip
    @district_name = district_name.to_s.strip
    @user_emails = parse_user_emails(user_emails)
    @triage_agent_email = triage_agent_email.to_s.strip
    @client = client
    @log = log
  end

  def validate!
    errors = portal_errors + triage_errors
    raise Invalid, errors.join("\n") if errors.any?
  end

  def call
    validate!

    municipality, responsible_subject = prepare_portal_records(email: email, pro: false)
    create_triage_responsible_subject!(responsible_subject)
    group_id = create_group!
    create_trigger!(group_id, responsible_subject)
    create_organization_with_users!

    ActiveRecord::Base.transaction do
      municipality.update!(active: true)
      responsible_subject.update!(active: true)
    end
    @log.call("Portal: municipality #{municipality.id} and responsible subject #{responsible_subject.id} activated")

    responsible_subject
  end

  private

  def portal_errors
    errors = municipality_errors + user_emails_errors

    user_emails.each do |user_email|
      user = User.find_by(email: user_email)
      errors << "Portal user #{user_email} is already a responsible subject user" if user.is_a?(User::ResponsibleSubject)
    end

    errors
  end

  def triage_errors
    errors = agent_errors + new_triage_setup_errors + organization_role_errors

    errors << "Triage organization #{name} already exists" if name.present? && @client.find_organization_by_name(name)
    user_emails.each do |user_email|
      user = @client.find_user_by_email(user_email)
      errors << "Triage user #{user_email} already exists (#{user.id}, organization: #{user.organization.inspect})" if user
    end

    errors
  end
end
