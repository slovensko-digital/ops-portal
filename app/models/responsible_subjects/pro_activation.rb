# Activates an existing responsible subject as PRO (with its own Backoffice) in the portal and in Triage.
#
# validate! checks everything up front and raises Invalid with all problems found, nothing is changed when anything is
# wrong. plan lists the changes, existing_setup_changes those to a Triage setup made by BasicActivation, which
# the caller confirms first. call then, in order:
#   - Triage: keeps or creates the responsible subject user, the group of the agent and the 700 trigger
#     (a responsible subject activated as BASIC has them, the agent is needed only to create them),
#   - Triage: takes the users of the organization named after the municipality out of it, the role
#     Externý zodpovedný subjekt becomes Customer, so Triage stops emailing them about the municipality's
#     tickets, then deletes the organization. The users themselves stay, in Triage and in the portal,
#   - portal: creates the Client and the Connector::Tenant of the Backoffice, and activates the responsible subject
#     (and its municipality) as PRO.
# Triage changes cannot be rolled back, a failure in the middle leaves the steps already done in place.
class ResponsibleSubjects::ProActivation
  include ResponsibleSubjects::TriageSetup

  class Invalid < StandardError; end

  CUSTOMER_ROLE = "Customer"
  EXTERNAL_RESPONSIBLE_SUBJECT_ROLE = "Externý zodpovedný subjekt"

  attr_reader :name, :backoffice_url, :connector_webhook_url, :backoffice_api_token, :backoffice_webhook_secret,
    :triage_agent_email

  def initialize(name:, backoffice_url:, connector_webhook_url:, backoffice_api_token:, backoffice_webhook_secret:, client:,
    triage_agent_email: nil, receive_customer_activities: false, log: ->(_message) { })
    @name = name.to_s.strip
    @backoffice_url = backoffice_url.to_s.strip
    @connector_webhook_url = connector_webhook_url.to_s.strip
    @backoffice_api_token = backoffice_api_token.to_s.strip
    @backoffice_webhook_secret = backoffice_webhook_secret.to_s.strip
    @triage_agent_email = triage_agent_email.to_s.strip
    @receive_customer_activities = receive_customer_activities
    @client = client
    @log = log
  end

  def validate!
    errors = portal_errors
    errors += triage_errors if errors.empty?
    raise Invalid, errors.join("\n") if errors.any?
  end

  def plan
    [
      triage_responsible_subject_user ? "Triage: keep responsible subject user #{triage_responsible_subject_user.id}" : "Triage: create responsible subject user",
      group ? "Triage: keep group #{name} (#{group.id})" : "Triage: create group #{name} for agent #{agent_name}",
      trigger ? "Triage: keep trigger #{trigger["name"].inspect} (#{trigger["id"]})" : "Triage: create trigger #{trigger_name}",
      *existing_setup_changes,
      "Portal: create Client and Connector::Tenant #{name}, Backoffice #{backoffice_url}, webhook #{connector_webhook_url}",
      "Portal: activate responsible subject #{responsible_subject.id} as PRO"
    ]
  end

  # changes to the Triage setup of a responsible subject activated as BASIC
  def existing_setup_changes
    return [] unless organization

    organization_users.map { |user| "Triage: take #{user_label(user)} out of organization #{name}#{", role #{EXTERNAL_RESPONSIBLE_SUBJECT_ROLE} -> #{CUSTOMER_ROLE}" if external_responsible_subject?(user)}" } +
      [ "Triage: delete organization #{name} (#{organization.id})" ]
  end

  def call
    validate!

    create_triage_responsible_subject!(responsible_subject) unless triage_responsible_subject_user
    group_id = group&.id || create_group!
    create_trigger!(group_id, responsible_subject) unless trigger
    remove_organization if organization

    tenant = ActiveRecord::Base.transaction { create_connector }
    @log.call("Portal: Client #{tenant.ops_api_subject_identifier}, Connector::Tenant #{tenant.id}, " \
      "responsible subject #{responsible_subject.id} activated as PRO")

    tenant
  end

  def responsible_subject
    @responsible_subject ||= ResponsibleSubject.find_by(subject_name: name) if name.present?
  end

  private

  def portal_errors
    errors = []
    errors << "NAME is missing" if name.blank?
    errors << "Responsible subject #{name} does not exist" if name.present? && responsible_subject.nil?
    if responsible_subject
      errors << "Responsible subject #{name} already has a Client" if responsible_subject.clients.any?
      municipality = responsible_subject.municipality
      if municipality && !municipality.active? && !MunicipalityBoundary.exists?(municipality: municipality)
        errors << "Municipality #{municipality.name} is inactive and has no boundary, run municipality_boundaries:import_all"
      end
    end
    errors << "Connector::Tenant #{name} already exists" if name.present? && Connector::Tenant.exists?(name: name)

    { "BACKOFFICE_URL" => backoffice_url, "CONNECTOR_WEBHOOK_URL" => connector_webhook_url }.each do |variable, url|
      errors << "#{variable} #{url.inspect} is not an http(s) URL" unless url.match?(%r{\Ahttps?://\S+\z})
    end
    errors << "BACKOFFICE_API_TOKEN is missing" if backoffice_api_token.blank?
    errors << "BACKOFFICE_WEBHOOK_SECRET is missing" if backoffice_webhook_secret.blank?

    errors
  end

  def triage_errors
    errors = []
    errors += agent_errors unless group && trigger
    errors << "Triage email address #{GROUP_EMAIL_ADDRESS} does not exist" if !group && !@client.find_email_address(GROUP_EMAIL_ADDRESS)
    errors << "Triage role #{PORTAL_TECH_ACCOUNT_ROLE} does not exist" if !group && !@client.find_role_by_name(PORTAL_TECH_ACCOUNT_ROLE)
    errors << "Triage role #{CUSTOMER_ROLE} does not exist" if organization && !@client.find_role_by_name(CUSTOMER_ROLE)
    errors
  end

  def triage_responsible_subject_user
    return @triage_responsible_subject_user if defined?(@triage_responsible_subject_user)

    @triage_responsible_subject_user = @client.find_user(responsible_subject.external_id) if responsible_subject.external_id.present?
  end

  def group
    return @group if defined?(@group)

    @group = @client.find_group_by_name(name)
  end

  def trigger
    return @trigger if defined?(@trigger)

    @trigger = triggers_for_municipality.first
  end

  def organization
    return @organization if defined?(@organization)

    @organization = @client.find_organization_by_name(name)
  end

  def organization_users
    @organization_users ||= Array(@client.get_organization(organization.id)["member_ids"]).map { @client.find_user(_1) }.compact
  end

  def remove_organization
    organization_users.each do |user|
      roles = Array(user.roles).map { _1 == EXTERNAL_RESPONSIBLE_SUBJECT_ROLE ? CUSTOMER_ROLE : _1 }.uniq
      @client.update_user!(user.id, organization_id: nil, roles: roles)
      @log.call("Triage: #{user_label(user)} taken out of organization #{name}, roles #{roles.join(", ")}")
    end

    @client.delete_organization!(organization.id)
    @log.call("Triage: organization #{name} (#{organization.id}) deleted")
  rescue RuntimeError => e
    # e.g. tickets still belong to the organization, its users are out of it already, so Triage emails nobody
    @log.call("Triage: organization #{name} (#{organization.id}) not deleted, delete it by hand: #{e.message}")
  end

  def create_connector
    client = Client.create!(name: name, responsible_subject: responsible_subject)
    tenant = Connector::Tenant.create!(name: name)

    api_key = OpenSSL::PKey::EC.generate("prime256v1")
    webhook_key = OpenSSL::PKey::EC.generate("prime256v1")

    client.update!(api_token_public_key: api_key.public_to_pem, webhook_private_key: webhook_key.to_pem, url: connector_webhook_url)
    tenant.update!(
      backoffice_api_token: backoffice_api_token,
      backoffice_webhook_secret: backoffice_webhook_secret,
      ops_api_token_private_key: api_key.to_pem,
      ops_webhook_public_key: webhook_key.public_to_pem,
      ops_api_subject_identifier: client.id,
      backoffice_url: backoffice_url,
      receive_customer_activities: @receive_customer_activities
    )

    responsible_subject.municipality&.update!(active: true)
    responsible_subject.update!(active: true, pro: true)

    tenant
  end

  def user_label(user)
    [ user.email.presence || user.login, "(#{user.id}, #{Array(user.roles).join(", ")})" ].join(" ")
  end

  def external_responsible_subject?(user)
    Array(user.roles).include?(EXTERNAL_RESPONSIBLE_SUBJECT_ROLE)
  end
end
