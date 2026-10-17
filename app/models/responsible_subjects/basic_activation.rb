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
class ResponsibleSubjects::BasicActivation
  class Invalid < StandardError; end

  RESPONSIBLE_SUBJECT_TYPE = "Mesto"
  GROUP_EMAIL_ADDRESS = "podnety@triaz.odkazprestarostu.sk"
  PORTAL_TECH_ACCOUNT_ROLE = "Portal Tech Account"
  AGENT_ROLE = "Agent"
  CUSTOMER_ROLE = "Customer"
  EXTERNAL_RESPONSIBLE_SUBJECT_ROLE = "Externý zodpovedný subjekt"
  TRIGGER_NAME_PREFIX = "700 - Priradenie podnetu skupine"

  attr_reader :name, :district_name, :user_emails, :triage_agent_email

  def initialize(boundary_id:, name:, district_name:, user_emails:, triage_agent_email:, client:, log: ->(_message) { })
    @boundary_id = boundary_id
    @name = name.to_s.strip
    @district_name = district_name.to_s.strip
    @user_emails = Array(user_emails).flat_map { _1.to_s.split(",") }.map(&:strip).compact_blank
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

    municipality, responsible_subject = create_portal_records
    responsible_subject.update!(external_id: @client.create_responsible_subject!(responsible_subject))
    @log.call("Triage: responsible subject user #{responsible_subject.external_id}")

    group_id = @client.create_group!(name, email_address_id: @client.find_email_address(GROUP_EMAIL_ADDRESS)["id"])
    @client.add_group_to_role!(PORTAL_TECH_ACCOUNT_ROLE, group_id)
    @log.call("Triage: group #{group_id}, accessible to role #{PORTAL_TECH_ACCOUNT_ROLE}")

    @log.call("Triage: organization #{@client.create_organization!(name)}")

    @client.add_user_to_group(agent.id, name)
    @log.call("Triage: agent #{agent_name} added to the group")

    @client.create_trigger!(trigger_attributes(group_id, responsible_subject))
    @log.call("Triage: trigger #{trigger_name}")

    user_emails.each do |user_email|
      roles = roles_for(user_email)
      user_id = @client.create_user!(email: user_email, organization: name, roles: roles, **names_from_email(user_email))
      Triage::UpdatePortalUserFromTriageJob.perform_now(user_id, triage_zammad_client: @client)
      @log.call("Triage and portal: user #{user_email} (#{user_id}), #{roles.join(", ")}")
    end

    ActiveRecord::Base.transaction do
      municipality.update!(active: true)
      responsible_subject.update!(active: true)
    end
    @log.call("Portal: municipality #{municipality.id} and responsible subject #{responsible_subject.id} activated")

    responsible_subject
  end

  def boundary
    @boundary ||= MunicipalityBoundary.find_by(id: @boundary_id)
  end

  def district
    @district ||= District.where("lower(name) = lower(?)", district_name).first if district_name.present?
  end

  def agent
    @agent ||= @client.find_user_by_email(triage_agent_email) if triage_agent_email.present?
  end

  # the responsible subject's email, the first user
  def email
    user_emails.first
  end

  def roles_for(user_email)
    user_email == email ? [ EXTERNAL_RESPONSIBLE_SUBJECT_ROLE ] : [ CUSTOMER_ROLE ]
  end

  def trigger_name
    "#{TRIGGER_NAME_PREFIX} #{name} #{agent_name}"
  end

  # meno.priezvisko@obec.sk is Meno Priezvisko, any other address is <local part> <municipality name>
  def names_from_email(user_email)
    parts = user_email.split("@").first.split(".")
    return { firstname: parts.first.capitalize, lastname: parts.last.capitalize } if parts.size == 2 && parts.all?(&:present?)

    { firstname: user_email.split("@").first, lastname: name }
  end

  private

  def portal_errors
    errors = []
    errors << "NAME is missing" if name.blank?
    errors << "USERS is missing" if user_emails.empty?
    user_emails.reject { |address| address.match?(URI::MailTo::EMAIL_REGEXP) }.each do |address|
      errors << "#{address} is not a valid email address"
    end
    errors << "USERS contains duplicate emails" if user_emails.map(&:downcase).uniq.size < user_emails.size

    if boundary.nil?
      errors << "Municipality boundary #{@boundary_id.inspect} does not exist, find it in /admin/municipality_boundaries"
    elsif boundary.boundary_kind != "municipality"
      errors << "Municipality boundary #{boundary.id} is a #{boundary.boundary_kind}, only municipality boundaries are supported"
    elsif boundary.municipality.present?
      errors << "Municipality boundary #{boundary.id} already belongs to municipality #{boundary.municipality.name} (#{boundary.municipality_id})"
    end

    if name.present?
      Municipality.where(name: name).find_each do |municipality|
        errors << "Municipality #{name} already exists (#{municipality.id}, active: #{municipality.active}, archived: #{municipality.archived}), " \
                  "activating it needs its archived issues restored, which this task does not do"
      end
      errors << "Responsible subject #{name} already exists" if ResponsibleSubject.exists?(subject_name: name)
    end
    errors << "Responsible subject type #{RESPONSIBLE_SUBJECT_TYPE} does not exist" unless responsible_subjects_type
    errors << "District #{district_name.inspect} does not exist, use one of: #{District.order(:name).pluck(:name).join(", ")}" unless district

    user_emails.each do |user_email|
      user = User.find_by(email: user_email)
      errors << "Portal user #{user_email} is already a responsible subject user" if user.is_a?(User::ResponsibleSubject)
    end

    errors
  end

  def triage_errors
    errors = []

    if agent.nil?
      errors << "Triage agent #{triage_agent_email.inspect} does not exist"
    elsif !Array(agent.roles).include?(AGENT_ROLE)
      errors << "Triage user #{triage_agent_email} (#{agent_name}) is not an agent"
    end

    errors << "Triage email address #{GROUP_EMAIL_ADDRESS} does not exist" unless @client.find_email_address(GROUP_EMAIL_ADDRESS)
    [ PORTAL_TECH_ACCOUNT_ROLE, CUSTOMER_ROLE, EXTERNAL_RESPONSIBLE_SUBJECT_ROLE ].each do |role|
      errors << "Triage role #{role} does not exist" unless @client.find_role_by_name(role)
    end

    if name.present?
      errors << "Triage group #{name} already exists" if @client.find_group_by_name(name)
      errors << "Triage organization #{name} already exists" if @client.find_organization_by_name(name)
      @client.get_triggers.select { |trigger| trigger_for_municipality?(trigger) }.each do |trigger|
        errors << "Triage trigger #{trigger["name"].inspect} (#{trigger["id"]}) already exists"
      end
    end

    user_emails.each do |user_email|
      user = @client.find_user_by_email(user_email)
      errors << "Triage user #{user_email} already exists (#{user.id}, organization: #{user.organization.inspect})" if user
    end

    errors
  end

  def create_portal_records
    ActiveRecord::Base.transaction do
      latitude, longitude = point_on_boundary
      municipality = Municipality.create!(name: name, district: district, latitude: latitude, longitude: longitude, active: false)
      boundary.update!(municipality: municipality)

      responsible_subject = ResponsibleSubject.create!(
        subject_name: name,
        email: email,
        municipality: municipality,
        responsible_subjects_type: responsible_subjects_type,
        pro: false,
        active: false
      )
      @log.call("Portal: municipality #{municipality.id} at #{latitude}, #{longitude}, responsible subject #{responsible_subject.id}, both inactive")

      [ municipality, responsible_subject ]
    end
  end

  # a point inside the boundary, unlike its centroid, which lies outside of a C shaped municipality
  def point_on_boundary
    MunicipalityBoundary.where(id: boundary.id)
      .pick(Arel.sql("ST_Y(ST_PointOnSurface(boundary))"), Arel.sql("ST_X(ST_PointOnSurface(boundary))"))
  end

  def trigger_attributes(group_id, responsible_subject)
    {
      name: trigger_name,
      condition: {
        "ticket.process_type" => { "operator" => "is", "value" => [ "portal_issue_verification", "portal_issue_triage" ] },
        "ticket.origin" => { "operator" => "is", "value" => [ "portal" ] },
        # Zammad matches the action only as a string, the trigger never fires with [ "create" ]
        "ticket.action" => { "operator" => "is", "value" => "create" },
        "ticket.address_municipality" => { "operator" => "is", "value" => [ name ] }
      },
      perform: {
        "ticket.group_id" => { "value" => group_id },
        "ticket.owner_id" => { "pre_condition" => "specific", "value" => agent.id },
        "ticket.responsible_subject" => { "value" => { "value" => responsible_subject.id, "label" => name } }
      },
      disable_notification: true,
      note: "#{TRIGGER_NAME_PREFIX} #{name}",
      activator: "action",
      execution_condition_mode: "selective",
      active: true
    }
  end

  # trigger names end with the agent's name, so "... Nižná Myšľa Jozef Mak" cannot be told from
  # a Nižná trigger by its name, its condition on the municipality can
  def trigger_for_municipality?(trigger)
    (agent.present? && trigger["name"] == trigger_name) ||
      Array(trigger.dig("condition", "ticket.address_municipality", "value")).include?(name)
  end

  def agent_name
    [ agent.firstname, agent.lastname ].compact_blank.join(" ")
  end

  def responsible_subjects_type
    @responsible_subjects_type ||= ResponsibleSubjects::Type.find_by(name: RESPONSIBLE_SUBJECT_TYPE)
  end
end
