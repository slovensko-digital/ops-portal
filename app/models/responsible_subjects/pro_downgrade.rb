# Downgrades a PRO responsible subject to BASIC: the municipality stops working its tickets in its Backoffice and gets
# Triage's emails again. Its tickets are all in Triage already, the Backoffice only had copies.
#
# validate! checks everything up front and raises Invalid with all problems found, nothing is changed when anything is
# wrong. plan lists the changes, which the caller confirms first. call then, in order:
#   - Triage: keeps the responsible subject user, the group of the agent and the 700 trigger as they are,
#   - Triage: creates the organization named after the municipality and its users, see
#     ResponsibleSubjects::OrganizationSetup. A user who is in Triage already, e.g. a customer left by ProUpgrade,
#     joins the organization instead,
#   - portal: disables the Client and the Connector::Tenant of the Backoffice and sets the responsible subject BASIC,
#     with the first of the users as its email.
# Triage changes cannot be rolled back, a failure in the middle leaves the steps already done in place.
class ResponsibleSubjects::ProDowngrade
  include ResponsibleSubjects::OrganizationSetup
  include ResponsibleSubjects::TriageSetup
  include ResponsibleSubjects::BackofficeConnection

  class Invalid < StandardError; end

  attr_reader :name, :user_emails

  def initialize(name:, user_emails:, client:, log: ->(_message) { })
    @name = name.to_s.strip
    @user_emails = parse_user_emails(user_emails)
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
      "Triage: create organization #{name}",
      *user_emails.map do |user_email|
        user = existing_triage_users[user_email]
        "Triage and portal: #{user ? "add existing user #{user_email} (#{user.id}, #{Array(user.roles).join(", ")})" : "create user #{user_email}"} " \
          "to organization #{name}, #{roles_for(user_email).join(", ")}"
      end,
      *responsible_subject.clients.active.map do |client|
        "Portal: disable Client #{client.id} and Connector::Tenant #{Connector::Tenant.where(ops_api_subject_identifier: client.id).pluck(:id).join(", ")}"
      end,
      "Portal: set responsible subject #{responsible_subject.id} BASIC, email #{email}"
    ]
  end

  def call
    validate!

    create_organization_with_users!(existing_users: existing_triage_users)

    ActiveRecord::Base.transaction do
      disconnect_backoffice!(responsible_subject)
      responsible_subject.update!(pro: false, email: email)
    end
    @log.call("Portal: Client and Connector::Tenant disabled, responsible subject #{responsible_subject.id} is BASIC")

    responsible_subject
  end

  def responsible_subject
    @responsible_subject ||= ResponsibleSubject.find_by(subject_name: name) if name.present?
  end

  # the agent is needed only to create the group and the trigger, which a downgrade keeps
  def triage_agent_email
    nil
  end

  private

  def portal_errors
    errors = user_emails_errors
    errors << "NAME is missing" if name.blank?
    if name.present? && responsible_subject.nil?
      errors << "Responsible subject #{name} does not exist"
    elsif responsible_subject && !responsible_subject.pro?
      errors << "Responsible subject #{name} is not PRO"
    elsif responsible_subject && !responsible_subject.active?
      errors << "Responsible subject #{name} is not active"
    elsif responsible_subject && responsible_subject.clients.active.none?
      errors << "Responsible subject #{name} has no active Client"
    end

    user_emails.each do |user_email|
      user = User.find_by(email: user_email)
      if user.is_a?(User::ResponsibleSubject) && user.responsible_subject != responsible_subject
        errors << "Portal user #{user_email} is a user of responsible subject #{user.responsible_subject&.subject_name}"
      end
    end

    errors
  end

  def triage_errors
    errors = existing_triage_setup_errors + organization_role_errors
    errors << "Triage organization #{name} already exists" if @client.find_organization_by_name(name)
    existing_triage_users.each do |user_email, user|
      errors << "Triage user #{user_email} (#{user.id}) is in organization #{user.organization}" if user.organization.present?
    end
    errors
  end

  def existing_triage_users
    @existing_triage_users ||= user_emails.filter_map { |user_email| [ user_email, @client.find_user_by_email(user_email) ] }.to_h.compact
  end
end
