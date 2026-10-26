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
end
