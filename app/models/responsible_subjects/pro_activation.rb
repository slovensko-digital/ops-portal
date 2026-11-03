# Activates a new municipality as a PRO (pro: true) responsible subject, with its own Backoffice, in the portal and in
# Triage. A BASIC responsible subject becomes PRO by ProUpgrade.
#
# validate! checks everything up front and raises Invalid with all problems found, nothing is created when anything is
# wrong. call then creates, in order:
#   - portal: the municipality at the boundary in its district (kraj) and its responsible subject, both inactive,
#   - Triage: the responsible subject user, a group for the agent named after the municipality and the 700 trigger
#     assigning portal tickets from the municipality to the agent. No organization and no users, the municipality
#     works its tickets in the Backoffice,
#   - portal: the Client and the Connector::Tenant of the Backoffice, then activates the municipality and the
#     responsible subject.
# Triage changes cannot be rolled back, a failure in the middle leaves the steps already done in place.
#
# use_existing_municipality: true, for local development only, see ResponsibleSubjects::MunicipalitySetup.
class ResponsibleSubjects::ProActivation
  include ResponsibleSubjects::MunicipalitySetup
  include ResponsibleSubjects::TriageSetup
  include ResponsibleSubjects::BackofficeConnection

  class Invalid < StandardError; end

  attr_reader :name, :district_name, :triage_agent_email, :backoffice_url, :connector_webhook_url, :backoffice_api_token,
    :backoffice_webhook_secret

  def initialize(boundary_id:, name:, district_name:, triage_agent_email:, backoffice_url:, connector_webhook_url:,
    backoffice_api_token:, backoffice_webhook_secret:, client:, receive_customer_activities: false,
    use_existing_municipality: false, log: ->(_message) { })
    @use_existing_municipality = use_existing_municipality
    @boundary_id = boundary_id
    @name = name.to_s.strip
    @district_name = district_name.to_s.strip
    @triage_agent_email = triage_agent_email.to_s.strip
    @backoffice_url = backoffice_url.to_s.strip
    @connector_webhook_url = connector_webhook_url.to_s.strip
    @backoffice_api_token = backoffice_api_token.to_s.strip
    @backoffice_webhook_secret = backoffice_webhook_secret.to_s.strip
    @receive_customer_activities = receive_customer_activities
    @client = client
    @log = log
  end

  def validate!
    errors = portal_errors + triage_errors
    raise Invalid, errors.join("\n") if errors.any?
  end

  def plan
    [
      "Portal: #{@use_existing_municipality ? "existing" : "create"} municipality and responsible subject #{name}, #{district.name}, boundary #{boundary.id}",
      "Triage: create responsible subject user, group #{name} for agent #{agent_name} and trigger #{trigger_name}",
      connect_backoffice_plan(nil),
      "Portal: activate the municipality and the responsible subject as PRO"
    ]
  end

  def call
    validate!

    municipality, responsible_subject = prepare_portal_records(email: nil, pro: true)
    create_triage_responsible_subject!(responsible_subject)
    group_id = create_group!
    create_trigger!(group_id, responsible_subject)

    tenant = ActiveRecord::Base.transaction do
      tenant = connect_backoffice!(responsible_subject)
      municipality.update!(active: true)
      responsible_subject.update!(active: true)
      tenant
    end
    @log.call("Portal: Client #{tenant.ops_api_subject_identifier}, Connector::Tenant #{tenant.id}, " \
      "municipality #{municipality.id} and responsible subject #{responsible_subject.id} activated as PRO")

    tenant
  end

  def responsible_subject
    ResponsibleSubject.find_by(subject_name: name) if name.present?
  end

  private

  def portal_errors
    errors = municipality_errors + backoffice_errors(nil)
    if responsible_subject&.active? && !responsible_subject.pro?
      errors << "Responsible subject #{name} is active as BASIC, make it PRO with responsible_subjects:upgrade_to_pro"
    end
    errors
  end

  def triage_errors
    errors = agent_errors + new_triage_setup_errors
    errors << "Triage organization #{name} already exists" if name.present? && @client.find_organization_by_name(name)
    errors
  end
end
