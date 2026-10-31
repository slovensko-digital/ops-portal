# The Triage setup of a municipality shared by BasicActivation and ProActivation: the responsible subject user, the
# group of the agent (volunteer) who reviews the municipality's tickets, and the 700 trigger assigning new portal
# tickets from the municipality to the group, the agent and the responsible subject.
#
# Expects name, triage_agent_email and @client (ZammadApiClient with an admin token).
module ResponsibleSubjects::TriageSetup
  GROUP_EMAIL_ADDRESS = "podnety@triaz.odkazprestarostu.sk"
  PORTAL_TECH_ACCOUNT_ROLE = "Portal Tech Account"
  AGENT_ROLE = "Agent"
  TRIGGER_NAME_PREFIX = "700 - Priradenie podnetu skupine"

  def agent
    @agent ||= @client.find_user_by_email(triage_agent_email) if triage_agent_email.present?
  end

  def trigger_name
    "#{TRIGGER_NAME_PREFIX} #{name} #{agent_name}"
  end

  private

  def agent_errors
    if agent.nil?
      [ "Triage agent #{triage_agent_email.inspect} does not exist" ]
    elsif !Array(agent.roles).include?(AGENT_ROLE)
      [ "Triage user #{triage_agent_email} (#{agent_name}) is not an agent" ]
    else
      []
    end
  end

  def create_triage_responsible_subject!(responsible_subject)
    responsible_subject.update!(external_id: @client.create_responsible_subject!(responsible_subject))
    @log.call("Triage: responsible subject user #{responsible_subject.external_id}")
  end

  def create_group!
    group_id = @client.create_group!(name, email_address_id: @client.find_email_address(GROUP_EMAIL_ADDRESS)["id"])
    @client.add_group_to_role!(PORTAL_TECH_ACCOUNT_ROLE, group_id)
    @log.call("Triage: group #{group_id}, accessible to role #{PORTAL_TECH_ACCOUNT_ROLE}")

    @client.add_user_to_group(agent.id, name)
    @log.call("Triage: agent #{agent_name} added to the group")

    group_id
  end

  def create_trigger!(group_id, responsible_subject)
    @client.create_trigger!(trigger_attributes(group_id, responsible_subject))
    @log.call("Triage: trigger #{trigger_name}")
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

  def triggers_for_municipality
    @client.get_triggers.select { |trigger| trigger_for_municipality?(trigger) }
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
end
