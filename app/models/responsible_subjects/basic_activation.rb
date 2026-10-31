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
# subject named NAME that the dev seeds create instead of creating them. The boundary and the district default to
# the municipality's own. The municipality's issues stay only in the portal, they are not sent to Triage.
class ResponsibleSubjects::BasicActivation
  include ResponsibleSubjects::TriageSetup

  class Invalid < StandardError; end

  RESPONSIBLE_SUBJECT_TYPE = "Mesto"
  CUSTOMER_ROLE = "Customer"
  EXTERNAL_RESPONSIBLE_SUBJECT_ROLE = "Externý zodpovedný subjekt"

  attr_reader :name, :district_name, :user_emails, :triage_agent_email

  def initialize(boundary_id:, name:, district_name:, user_emails:, triage_agent_email:, client:, use_existing_municipality: false, log: ->(_message) { })
    @use_existing_municipality = use_existing_municipality
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

    municipality, responsible_subject = @use_existing_municipality ? prepare_existing_portal_records : create_portal_records
    create_triage_responsible_subject!(responsible_subject)
    group_id = create_group!
    @log.call("Triage: organization #{@client.create_organization!(name)}")
    create_trigger!(group_id, responsible_subject)

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
    @boundary ||= if @boundary_id.blank? && @use_existing_municipality
      MunicipalityBoundary.municipalities.find_by(municipality: existing_municipality) if existing_municipality
    else
      MunicipalityBoundary.find_by(id: @boundary_id)
    end
  end

  def district
    @district ||= if district_name.blank? && @use_existing_municipality
      existing_municipality&.district
    elsif district_name.present?
      District.where("lower(name) = lower(?)", district_name).first
    end
  end

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

  def portal_errors
    errors = []
    errors << "NAME is missing" if name.blank?
    errors << "USERS is missing" if user_emails.empty?
    user_emails.reject { |address| address.match?(URI::MailTo::EMAIL_REGEXP) }.each do |address|
      errors << "#{address} is not a valid email address"
    end
    errors << "USERS contains duplicate emails" if user_emails.map(&:downcase).uniq.size < user_emails.size

    if boundary.nil? && @boundary_id.blank? && @use_existing_municipality
      errors << "Municipality #{name} has no boundary, run municipality_boundaries:import_all or pass BOUNDARY_ID" if existing_municipality
    elsif boundary.nil?
      errors << "Municipality boundary #{@boundary_id.inspect} does not exist, find it in /admin/municipality_boundaries"
    elsif boundary.boundary_kind != "municipality"
      errors << "Municipality boundary #{boundary.id} is a #{boundary.boundary_kind}, only municipality boundaries are supported"
    elsif boundary.municipality.present? && !(@use_existing_municipality && boundary.municipality == existing_municipality)
      errors << "Municipality boundary #{boundary.id} already belongs to municipality #{boundary.municipality.name} (#{boundary.municipality_id})"
    end

    if name.present? && @use_existing_municipality
      errors.concat(existing_municipality_errors)
    elsif name.present?
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
    errors = agent_errors

    errors << "Triage email address #{GROUP_EMAIL_ADDRESS} does not exist" unless @client.find_email_address(GROUP_EMAIL_ADDRESS)
    [ PORTAL_TECH_ACCOUNT_ROLE, CUSTOMER_ROLE, EXTERNAL_RESPONSIBLE_SUBJECT_ROLE ].each do |role|
      errors << "Triage role #{role} does not exist" unless @client.find_role_by_name(role)
    end

    if name.present?
      errors << "Triage group #{name} already exists" if @client.find_group_by_name(name)
      errors << "Triage organization #{name} already exists" if @client.find_organization_by_name(name)
      triggers_for_municipality.each do |trigger|
        errors << "Triage trigger #{trigger["name"].inspect} (#{trigger["id"]}) already exists"
      end
    end

    user_emails.each do |user_email|
      user = @client.find_user_by_email(user_email)
      errors << "Triage user #{user_email} already exists (#{user.id}, organization: #{user.organization.inspect})" if user
    end

    errors
  end

  def existing_municipality_errors
    return [ "Municipality #{name} does not exist, EXISTING_MUNICIPALITY activates only an existing one" ] unless existing_municipality

    errors = []
    errors << "Municipality #{name} is already active" if existing_municipality.active?
    errors << "Municipality #{name} is archived" if existing_municipality.archived?
    if district && existing_municipality.district != district
      errors << "Municipality #{name} is in district #{existing_municipality.district&.name}, not #{district.name}"
    end

    if existing_responsible_subject.nil?
      errors << "Responsible subject #{name} of municipality #{name} does not exist"
    else
      errors << "Responsible subject #{name} is already active" if existing_responsible_subject.active?
      errors << "Responsible subject #{name} already has Triage user #{existing_responsible_subject.external_id}" if existing_responsible_subject.external_id.present?
    end

    errors
  end

  def existing_municipality
    @existing_municipality ||= Municipality.find_by(name: name) if name.present?
  end

  def existing_responsible_subject
    @existing_responsible_subject ||= ResponsibleSubject.find_by(subject_name: name, municipality: existing_municipality, municipality_district: nil) if existing_municipality
  end

  def prepare_existing_portal_records
    ActiveRecord::Base.transaction do
      boundary.update!(municipality: existing_municipality)
      existing_responsible_subject.update!(email: email, pro: false)
      @log.call("Portal: existing municipality #{existing_municipality.id} and responsible subject #{existing_responsible_subject.id}, both inactive")

      [ existing_municipality, existing_responsible_subject ]
    end
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

  def responsible_subjects_type
    @responsible_subjects_type ||= ResponsibleSubjects::Type.find_by(name: RESPONSIBLE_SUBJECT_TYPE)
  end
end
