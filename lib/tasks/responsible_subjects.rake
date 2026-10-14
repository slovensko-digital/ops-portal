namespace :responsible_subjects do
  ACTIVATE_BASIC_HELP = <<~HELP.freeze
    Activates a new municipality as a BASIC (pro: false) responsible subject in the portal and in Triage.

    Usage:
      bin/rails responsible_subjects:activate_basic \\
        BOUNDARY_ID=1273 \\
        NAME="Nižná" \\
        USERS="starosta@nizna.sk, jan.novak@nizna.sk, podatelna@nizna.sk" \\
        TRIAGE_ZAMMAD_AGENT_ID=42 \\
        DRY_RUN=1

    Arguments:
      BOUNDARY_ID             id of the municipality boundary (not a district), see /admin/municipality_boundaries
      NAME                    name of the municipality and its responsible subject, e.g. Nižná
      USERS                   emails of people who reply to issues and log in to the portal on behalf of the
                              responsible subject, comma separated, the first one is the responsible subject's
                              email and gets notified about the municipality's tickets
      TRIAGE_ZAMMAD_AGENT_ID  Triage Zammad user id of the agent (volunteer) who reviews, accepts and rejects
                              incoming issues from the municipality
      DRY_RUN=1               only validate, change nothing

    First validates everything and stops without changing anything when:
      - the boundary does not exist, is a district or already belongs to a municipality,
      - a municipality or responsible subject named NAME exists in the portal (a hidden municipality has
        archived issues that need Triage in import mode to restore, this task does not handle it),
      - a group, organization or 700 trigger for NAME exists in Triage,
      - any of USERS exists in Triage, or is a responsible subject user in the portal,
      - the agent does not exist or is not an agent, an email address is invalid,
      - a Triage role the task assigns does not exist.

    Then creates:
      Portal  municipality NAME at the boundary (inactive), responsible subject NAME of type Mesto with the
              first of USERS as its email (inactive)
      Triage  the responsible subject's user with role Zodpovedný Subjekt (its external_id),
              group NAME for the agent, sending from podnety@triaz.odkazprestarostu.sk and accessible to the
              Portal Tech Account role, the agent gets full access to it,
              trigger "700 - Priradenie podnetu skupine NAME <agent>" assigning new portal tickets from NAME
              to the group, the agent and the responsible subject,
              organization NAME with a user for every one of USERS, role Customer, the first one also
              Externý zodpovedný subjekt (meno.priezvisko@... is Meno Priezvisko, otherwise the first name is
              the part before @ and the last name is NAME)
      Portal  a responsible subject user for every one of USERS, then activates the municipality and the
              responsible subject

    Triage changes cannot be rolled back. When a step fails, the steps printed before it are done and have to be
    finished or removed by hand.
  HELP

  desc "Activate a new BASIC municipality in the portal and Triage, run without arguments for help"
  task activate_basic: :environment do
    required = %w[BOUNDARY_ID NAME USERS TRIAGE_ZAMMAD_AGENT_ID]
    if ENV["HELP"].present? || required.all? { ENV[_1].blank? }
      puts ACTIVATE_BASIC_HELP
      next
    end

    activation = ResponsibleSubjects::BasicActivation.new(
      boundary_id: ENV["BOUNDARY_ID"],
      name: ENV["NAME"],
      user_emails: ENV["USERS"],
      triage_agent_id: ENV["TRIAGE_ZAMMAD_AGENT_ID"],
      log: ->(message) { puts message }
    )

    begin
      activation.validate!
    rescue ResponsibleSubjects::BasicActivation::Invalid => e
      abort "Nothing was changed:\n#{e.message.gsub(/^/, "  - ")}"
    end

    puts <<~SUMMARY
      Municipality boundary #{activation.boundary.id} -> municipality and responsible subject #{activation.name}
      Responsible subject email: #{activation.email}
      Triage agent: #{activation.triage_agent_id}, trigger: #{activation.trigger_name}
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
