# The Triage setup of a municipality shared by BasicActivation, ProActivation, ProUpgrade and ProDowngrade: the responsible subject user, the
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

  # for a municipality with no Triage setup yet
  def new_triage_setup_errors
    errors = []
    errors << "Triage email address #{GROUP_EMAIL_ADDRESS} does not exist" unless @client.find_email_address(GROUP_EMAIL_ADDRESS)
    errors << "Triage role #{PORTAL_TECH_ACCOUNT_ROLE} does not exist" unless @client.find_role_by_name(PORTAL_TECH_ACCOUNT_ROLE)
    return errors if name.blank?

    errors << "Triage group #{name} already exists" if @client.find_group_by_name(name)
    triggers_for_municipality.each do |trigger|
      errors << "Triage trigger #{trigger["name"].inspect} (#{trigger["id"]}) already exists"
    end
    errors
  end

  # for a municipality activated before, its group and 700 trigger stay as they are
  def existing_triage_setup_errors
    errors = []
    errors << "Triage group #{name} does not exist" unless @client.find_group_by_name(name)
    errors << "Triage 700 trigger for #{name} does not exist" if triggers_for_municipality.empty?
    errors
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

  # The same condition and perform as a trigger saved in the Triage admin UI (expert mode): a new portal ticket from
  # the municipality, or a ticket whose responsible subject is changed to this one, goes to the group and the agent.
  def trigger_attributes(group_id, responsible_subject)
    {
      name: trigger_name,
      condition: {
        "operator" => "OR",
        "conditions" => [
          {
            "operator" => "AND",
            "conditions" => [
              { "name" => "ticket.process_type", "operator" => "is", "value" => [ "portal_issue_verification", "portal_issue_triage" ] },
              # Zammad matches the action only as a string, the trigger never fires with [ "create" ]
              { "name" => "ticket.action", "operator" => "is", "value" => "create" },
              { "name" => "ticket.origin", "operator" => "is", "value" => [ "portal" ] },
              { "name" => "ticket.address_municipality", "operator" => "is", "value" => address_municipality_values(responsible_subject.municipality) }
            ]
          },
          {
            "operator" => "AND",
            "conditions" => [
              { "name" => "ticket.responsible_subject", "operator" => "has changed", "value" => [] },
              { "name" => "ticket.responsible_subject", "operator" => "is", "value" => [ { "label" => name, "value" => responsible_subject.id } ] }
            ]
          }
        ]
      },
      perform: {
        "ticket.group_id" => { "value" => group_id.to_s },
        "ticket.owner_id" => { "pre_condition" => "specific", "value" => agent.id.to_s, "value_completion" => "#{agent_name} <#{agent.email}>" },
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

  # A ticket of a city with districts has "City::District" in address_municipality (ZammadApiClient#build_ticket_municipality)
  # and Zammad's "is" matches the exact value, a tree_select parent does not match its children. Plain "City" is for
  # an address outside every district boundary.
  def address_municipality_values(municipality)
    [ name, *municipality.municipality_districts.alphabetical.map { |district| "#{name}::#{district.name}" } ]
  end

  # trigger names end with the agent's name, so "... Nižná Myšľa Jozef Mak" cannot be told from
  # a Nižná trigger by its name, its condition on the municipality ("Nižná" or "Nižná::<district>") can
  def trigger_for_municipality?(trigger)
    (agent.present? && trigger["name"] == trigger_name) ||
      trigger_municipality_values(trigger["condition"]).any? { |value| value == name || value.to_s.start_with?("#{name}::") }
  end

  def trigger_municipality_values(condition)
    condition_leaves(condition)
      .select { |field, spec| field == "ticket.address_municipality" && spec.is_a?(Hash) && spec["operator"] == "is" }
      .flat_map { |_field, spec| Array(spec["value"]) }
  end

  # [field, spec] pairs of a condition in either format Zammad stores: flat { "ticket.x" => spec } or, saved from the
  # admin UI in expert mode, nested { "operator" => "OR", "conditions" => [ { "name" => "ticket.x", ... }, ... ] }
  def condition_leaves(condition)
    return [] unless condition.is_a?(Hash)
    return Array(condition["conditions"]).flat_map { |child| condition_leaves(child) } if condition.key?("conditions")
    return [ [ condition["name"], condition ] ] if condition.key?("name")

    condition.to_a
  end

  def agent_name
    [ agent.firstname, agent.lastname ].compact_blank.join(" ")
  end
end
