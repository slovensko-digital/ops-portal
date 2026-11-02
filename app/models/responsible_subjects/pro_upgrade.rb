# Upgrades an active BASIC responsible subject (activated by BasicActivation or downgraded by ProDowngrade) to PRO,
# with its own Backoffice, in the portal and in Triage.
#
# validate! checks everything up front and raises Invalid with all problems found, nothing is changed when anything is
# wrong. plan lists the changes, organization_changes those to the organization and its users, which the caller
# confirms first. call then, in order:
#   - Triage: keeps the responsible subject user, the group of the agent and the 700 trigger as they are,
#   - Triage: takes the users of the organization named after the municipality out of it, the role
#     Externý zodpovedný subjekt becomes Customer, so Triage stops emailing them about the municipality's
#     tickets, then deletes the organization. The users themselves stay in Triage and in the portal, where
#     Triage::UpdatePortalUserFromTriageJob makes them citizens, they are no longer in the organization,
#   - portal: creates the Client and the Connector::Tenant of the Backoffice, or enables those disabled by a
#     downgrade, and sets the responsible subject PRO.
# Triage changes cannot be rolled back, a failure in the middle leaves the steps already done in place.
class ResponsibleSubjects::ProUpgrade
  include ResponsibleSubjects::TriageSetup
  include ResponsibleSubjects::BackofficeConnection

  class Invalid < StandardError; end

  CUSTOMER_ROLE = ResponsibleSubjects::OrganizationSetup::CUSTOMER_ROLE
  EXTERNAL_RESPONSIBLE_SUBJECT_ROLE = ResponsibleSubjects::OrganizationSetup::EXTERNAL_RESPONSIBLE_SUBJECT_ROLE

  attr_reader :name, :backoffice_url, :connector_webhook_url, :backoffice_api_token, :backoffice_webhook_secret

  def initialize(name:, backoffice_url:, connector_webhook_url:, backoffice_api_token:, backoffice_webhook_secret:, client:,
    receive_customer_activities: false, log: ->(_message) { })
    @name = name.to_s.strip
    @backoffice_url = backoffice_url.to_s.strip
    @connector_webhook_url = connector_webhook_url.to_s.strip
    @backoffice_api_token = backoffice_api_token.to_s.strip
    @backoffice_webhook_secret = backoffice_webhook_secret.to_s.strip
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
      "Triage: keep responsible subject user #{responsible_subject.external_id}, group #{name} and the 700 trigger",
      *organization_changes,
      connect_backoffice_plan(responsible_subject),
      "Portal: set responsible subject #{responsible_subject.id} PRO"
    ]
  end

  def organization_changes
    return [] unless organization

    organization_users.map { |user| "Triage: take #{user_label(user)} out of organization #{name}#{", role #{EXTERNAL_RESPONSIBLE_SUBJECT_ROLE} -> #{CUSTOMER_ROLE}" if external_responsible_subject?(user)}" } +
      [ "Triage: delete organization #{name} (#{organization.id})" ]
  end

  def call
    validate!

    remove_organization if organization

    tenant = ActiveRecord::Base.transaction do
      tenant = connect_backoffice!(responsible_subject)
      responsible_subject.update!(pro: true)
      tenant
    end
    @log.call("Portal: Client #{tenant.ops_api_subject_identifier}, Connector::Tenant #{tenant.id}, " \
      "responsible subject #{responsible_subject.id} is PRO")

    tenant
  end

  def responsible_subject
    @responsible_subject ||= ResponsibleSubject.find_by(subject_name: name) if name.present?
  end

  # the agent is needed only to create the group and the trigger, which an upgrade keeps
  def triage_agent_email
    nil
  end

  private

  def portal_errors
    errors = []
    errors << "NAME is missing" if name.blank?
    if name.present? && responsible_subject.nil?
      errors << "Responsible subject #{name} does not exist, activate it with responsible_subjects:activate_pro"
    elsif responsible_subject&.pro?
      errors << "Responsible subject #{name} is already PRO"
    elsif responsible_subject && !responsible_subject.active?
      errors << "Responsible subject #{name} is not active, activate it with responsible_subjects:activate_pro"
    elsif responsible_subject && responsible_subject.external_id.blank?
      errors << "Responsible subject #{name} has no Triage user"
    end

    errors + backoffice_errors(responsible_subject)
  end

  def triage_errors
    errors = existing_triage_setup_errors
    errors << "Triage responsible subject user #{responsible_subject.external_id} does not exist" unless @client.find_user(responsible_subject.external_id)
    errors << "Triage role #{CUSTOMER_ROLE} does not exist" if organization && !@client.find_role_by_name(CUSTOMER_ROLE)
    errors
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
      # Triage sends the same as its user.updated webhook, which does not reach a portal that is down
      Triage::UpdatePortalUserFromTriageJob.perform_now(user.id, triage_zammad_client: @client)
      @log.call("Triage and portal: #{user_label(user)} taken out of organization #{name}, roles #{roles.join(", ")}")
    end

    @client.delete_organization!(organization.id)
    @log.call("Triage: organization #{name} (#{organization.id}) deleted")
  rescue RuntimeError => e
    # e.g. tickets still belong to the organization, its users are out of it already, so Triage emails nobody
    @log.call("Triage: organization #{name} (#{organization.id}) not deleted, delete it by hand: #{e.message}")
  end

  def user_label(user)
    [ user.email.presence || user.login, "(#{user.id}, #{Array(user.roles).join(", ")})" ].join(" ")
  end

  def external_responsible_subject?(user)
    Array(user.roles).include?(EXTERNAL_RESPONSIBLE_SUBJECT_ROLE)
  end
end
