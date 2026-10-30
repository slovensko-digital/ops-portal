namespace :responsible_subjects do
  ACTIVATE_BASIC_HELP = <<~HELP.freeze
    Activates a new municipality as a BASIC (pro: false) responsible subject in the portal and in Triage.

    Usage:
      bin/rails responsible_subjects:activate_basic \\
        BOUNDARY_ID=1273 \\
        NAME="Nižná" \\
        DISTRICT="Žilinský kraj" \\
        USERS="podatelna@nizna.sk, starosta@nizna.sk, jan.novak@nizna.sk" \\
        TRIAGE_ZAMMAD_AGENT_EMAIL=jozef.mak@odkazprestarostu.sk \\
        DRY_RUN=1

    Arguments:
      BOUNDARY_ID             id of the municipality boundary (not a district), see /admin/municipality_boundaries
      NAME                    name of the municipality and its responsible subject, e.g. Nižná
      DISTRICT                name of the district (kraj) of the municipality, e.g. Žilinský kraj
      USERS                   emails of people who log in to the portal on behalf of the responsible subject,
                              comma separated, the first one is the responsible subject's email and is notified
                              about the municipality's tickets, the others reply to issues
      TRIAGE_ZAMMAD_AGENT_EMAIL  email of the Triage Zammad agent (volunteer) who reviews, accepts and rejects
                                 incoming issues from the municipality
      DRY_RUN=1               only validate, change nothing
      EXISTING_MUNICIPALITY=1 local development only: activates the inactive municipality and responsible subject
                              named NAME, which the dev seeds create, instead of creating them. BOUNDARY_ID and
                              DISTRICT default to the municipality's own. Its issues are not sent to Triage.
                              E.g. after db:seed, municipality_boundaries:import_all and with the local Triage up:
                                bin/rails responsible_subjects:activate_basic EXISTING_MUNICIPALITY=1 NAME=Trnava \\
                                  USERS="podatelna@trnava.example.com, jan.novak@trnava.example.com" \\
                                  TRIAGE_ZAMMAD_AGENT_EMAIL=dobrovolnik@example.org

    Environment:
      TRIAGE_ZAMMAD_ADMIN_API_TOKEN  required, a Triage Zammad API token of an admin, with at least the
                                     permissions admin.group, admin.organization, admin.role, admin.trigger,
                                     admin.user and ticket.agent. The portal's TRIAGE_ZAMMAD_API_TOKEN cannot
                                     manage roles, organizations and triggers. Create it in Triage under
                                     Profile > Token Access. Deployed apps get it as a Kamal secret. Locally,
                                     .env.sample has the local Triage admin's token, or pass it for the run, e.g.
                                     TRIAGE_ZAMMAD_ADMIN_API_TOKEN=... bin/rails responsible_subjects:activate_basic ...

    First validates everything and stops without changing anything when:
      - the boundary does not exist, is a district or already belongs to a municipality,
      - a municipality or responsible subject named NAME exists in the portal (a hidden municipality has
        archived issues that need Triage in import mode to restore, this task does not handle it),
      - a group, organization or 700 trigger for NAME exists in Triage,
      - any of USERS exists in Triage, or is a responsible subject user in the portal,
      - the district does not exist,
      - the agent does not exist or is not an agent, an email address is invalid,
      - a Triage role the task assigns does not exist.

    Then creates:
      Portal  municipality NAME in DISTRICT at the boundary (inactive), responsible subject NAME of type Mesto with the
              first of USERS as its email (inactive)
      Triage  the responsible subject's user with role Zodpovedný Subjekt (its external_id),
              group NAME for the agent, sending from podnety@triaz.odkazprestarostu.sk and accessible to the
              Portal Tech Account role, the agent gets full access to it,
              trigger "700 - Priradenie podnetu skupine NAME <agent>" assigning new portal tickets from NAME
              to the group, the agent and the responsible subject,
              organization NAME with a user for the first of USERS with role Externý zodpovedný subjekt
              (Triage notifies the organization's users with this role) and for each of the other USERS
              with role Customer
              (meno.priezvisko@... is Meno Priezvisko, otherwise the first name is the part before @ and the
              last name is NAME)
      Portal  a responsible subject user for every one of USERS, then activates the municipality and the
              responsible subject

    Triage changes cannot be rolled back. When a step fails, the steps printed before it are done and have to be
    finished or removed by hand.
  HELP

  desc "Activate a new BASIC municipality in the portal and Triage, run without arguments for help"
  task activate_basic: :environment do
    required = %w[BOUNDARY_ID NAME DISTRICT USERS TRIAGE_ZAMMAD_AGENT_EMAIL]
    if ENV["HELP"].present? || required.all? { ENV[_1].blank? }
      puts ACTIVATE_BASIC_HELP
      next
    end

    use_existing_municipality = ENV["EXISTING_MUNICIPALITY"].present?
    abort "EXISTING_MUNICIPALITY is for local development only" if use_existing_municipality && !Rails.env.development?

    admin_token = ENV["TRIAGE_ZAMMAD_ADMIN_API_TOKEN"]
    abort "TRIAGE_ZAMMAD_ADMIN_API_TOKEN is missing, run without arguments for help" if admin_token.blank?

    activation = ResponsibleSubjects::BasicActivation.new(
      boundary_id: ENV["BOUNDARY_ID"],
      name: ENV["NAME"],
      district_name: ENV["DISTRICT"],
      user_emails: ENV["USERS"],
      triage_agent_email: ENV["TRIAGE_ZAMMAD_AGENT_EMAIL"],
      client: ZammadApiClient.new(url: ENV.fetch("TRIAGE_ZAMMAD_URL"), http_token: admin_token),
      use_existing_municipality: use_existing_municipality,
      log: ->(message) { puts message }
    )

    begin
      activation.validate!
    rescue ResponsibleSubjects::BasicActivation::Invalid => e
      abort "Nothing was changed:\n#{e.message.gsub(/^/, "  - ")}"
    end

    puts <<~SUMMARY
      Municipality boundary #{activation.boundary.id} -> municipality and responsible subject #{activation.name}, #{activation.district.name}
      Responsible subject email: #{activation.email}
      Triage agent: #{activation.triage_agent_email} (#{activation.agent.id}), trigger: #{activation.trigger_name}
      Users:
      #{activation.user_emails.map { |email| "  #{email} (#{activation.names_from_email(email).values.join(" ")}), #{activation.roles_for(email).join(", ")}" }.join("\n")}
    SUMMARY

    if ENV["DRY_RUN"].present?
      puts "Valid, nothing was changed (DRY_RUN)."
      next
    end

    activation.call
    puts "Done."
  end

  ACTIVATE_PRO_HELP = <<~HELP.freeze
    Activates an existing responsible subject as PRO, with its own Backoffice, in the portal and in Triage.

    Usage:
      bin/rails responsible_subjects:activate_pro \\
        NAME="Malacky" \\
        BACKOFFICE_URL=https://malacky.odkazprestarostu.sk/ \\
        DRY_RUN=1

    Arguments:
      NAME                       subject name of the responsible subject, e.g. Malacky
      BACKOFFICE_URL             URL of the Backoffice Zammad, the Connector calls its API
      CONNECTOR_WEBHOOK_URL      the portal's Connector webhook, the portal sends the Backoffice's issues to it,
                                 defaults to the CONNECTOR_WEBHOOK_URL of the environment
      BACKOFFICE_API_TOKEN       the Backoffice's API_TOKEN, generated when empty
      BACKOFFICE_WEBHOOK_SECRET  the Backoffice's WEBHOOK_SECRET, generated when empty
      TRIAGE_ZAMMAD_AGENT_EMAIL  email of the Triage agent (volunteer) for the municipality's tickets, needed only when
                                 its Triage group or 700 trigger is missing (it was not activated as BASIC)
      RECEIVE_CUSTOMER_ACTIVITIES=1  the Backoffice also gets the comments of citizens
      DRY_RUN=1                  only validate and list the changes, change nothing
      YES=1                      do not ask to confirm the changes to an existing BASIC setup

    Environment:
      TRIAGE_ZAMMAD_ADMIN_API_TOKEN  required, see responsible_subjects:activate_basic

    First validates everything and stops without changing anything when:
      - the responsible subject does not exist, or already has a Client, or a Connector::Tenant named NAME exists,
      - its municipality is inactive and has no boundary,
      - the agent is needed and does not exist or is not an agent, a Triage role or email address is missing.

    Then lists the changes. For a responsible subject activated as BASIC, it asks to confirm them first:
      Triage  keeps the responsible subject user, group NAME and the 700 trigger, or creates the missing ones
              (see responsible_subjects:activate_basic),
              takes the users of organization NAME out of it, role Externý zodpovedný subjekt becomes Customer,
              so Triage stops emailing them about the tickets, then deletes the organization. The users stay in
              Triage and in the portal, what should happen to them is not decided yet.
      Portal  the Client and Connector::Tenant of the Backoffice, then activates the responsible subject (and its
              municipality) with pro true

    Prints the environment of the Backoffice deployment at the end.

    Triage changes cannot be rolled back. When a step fails, the steps printed before it are done and have to be
    finished or removed by hand.
  HELP

  desc "Activate an existing responsible subject as PRO with its own Backoffice, run without arguments for help"
  task activate_pro: :environment do
    if ENV["HELP"].present? || %w[NAME BACKOFFICE_URL].all? { ENV[_1].blank? }
      puts ACTIVATE_PRO_HELP
      next
    end

    admin_token = ENV["TRIAGE_ZAMMAD_ADMIN_API_TOKEN"]
    abort "TRIAGE_ZAMMAD_ADMIN_API_TOKEN is missing, run without arguments for help" if admin_token.blank?

    activation = ResponsibleSubjects::ProActivation.new(
      name: ENV["NAME"],
      backoffice_url: ENV["BACKOFFICE_URL"],
      connector_webhook_url: ENV["CONNECTOR_WEBHOOK_URL"],
      backoffice_api_token: ENV["BACKOFFICE_API_TOKEN"].presence || SecureRandom.alphanumeric(43),
      backoffice_webhook_secret: ENV["BACKOFFICE_WEBHOOK_SECRET"].presence || SecureRandom.alphanumeric(43),
      triage_agent_email: ENV["TRIAGE_ZAMMAD_AGENT_EMAIL"],
      receive_customer_activities: ENV["RECEIVE_CUSTOMER_ACTIVITIES"].present?,
      client: ZammadApiClient.new(url: ENV.fetch("TRIAGE_ZAMMAD_URL"), http_token: admin_token),
      log: ->(message) { puts message }
    )

    begin
      activation.validate!
    rescue ResponsibleSubjects::ProActivation::Invalid => e
      abort "Nothing was changed:\n#{e.message.gsub(/^/, "  - ")}"
    end

    puts activation.plan.map { "  #{_1}" }

    if ENV["DRY_RUN"].present?
      puts "Valid, nothing was changed (DRY_RUN)."
      next
    end

    if activation.existing_setup_changes.any? && ENV["YES"].blank?
      abort "#{activation.name} was activated as BASIC, confirm the changes above with YES=1" unless $stdin.tty?

      print "#{activation.name} was activated as BASIC, make the changes above? [y/N] "
      abort "Nothing was changed." unless $stdin.gets.to_s.strip.casecmp?("y")
    end

    tenant = activation.call
    puts <<~ENVIRONMENT
      Done. The Backoffice's environment:
        OPS_RESPONSIBLE_SUBJECT=#{activation.responsible_subject.subject_name}
        OPS_RESPONSIBLE_SUBJECT_ID=#{activation.responsible_subject.id}
        WEBHOOK_TENANT_ID=#{tenant.id}
        API_TOKEN=#{tenant.backoffice_api_token}
        WEBHOOK_SECRET=#{tenant.backoffice_webhook_secret}
        OPS_CONNECTOR_URL=#{URI.join(activation.connector_webhook_url, "/")}
    ENVIRONMENT
  end
end
