require "test_helper"
require "test_helpers/zammad_helper"

class ResponsibleSubjects::BasicActivationTest < ActiveSupport::TestCase
  include ZammadHelper

  setup do
    @client = ZammadApiClient.new(url: ENV.fetch("TRIAGE_ZAMMAD_URL"), http_token: "token")
    stub_triage
  end

  test "call creates the municipality, the responsible subject and their Triage setup, then activates them" do
    stub_creation

    responsible_subject = build_activation.call

    municipality = responsible_subject.municipality
    assert_equal "Nižná", municipality.name
    assert_equal districts(:za_kraj), municipality.district
    assert_predicate municipality, :active?
    assert_equal municipality, municipality_boundaries(:unmatched_municipality).reload.municipality
    assert MunicipalityBoundary.containing_point(municipality.latitude, municipality.longitude).exists?(municipality_boundaries(:unmatched_municipality).id)

    assert_equal "Nižná", responsible_subject.subject_name
    assert_equal "starosta@nizna.sk", responsible_subject.email
    assert_equal responsible_subjects_types(:city), responsible_subject.responsible_subjects_type
    assert_predicate responsible_subject, :active?
    assert_not responsible_subject.pro
    assert_equal "58", responsible_subject.external_id
    assert_requested :post, zammad_url("users"), query: hash_including({}), body: hash_including(
      "firstname" => "Nižná", "login" => "ops-rs-#{responsible_subject.id}", "roles" => [ "Zodpovedný Subjekt" ]
    )

    assert_requested :post, zammad_url("groups"), query: hash_including({}),
      body: hash_including("name" => "Nižná", "email_address_id" => 1)
    assert_requested :put, zammad_url("roles/8"), body: { "group_ids" => { "1" => [ "full" ], "9" => [ "full" ] } }
    assert_requested :post, zammad_url("organizations"), query: hash_including({}), body: hash_including("name" => "Nižná", "shared" => false)
    assert_requested :put, zammad_url("users/3"), query: hash_including({}),
      body: { "groups" => { "Incoming" => "full", "Nižná" => "full" } }
    assert_requested :post, zammad_url("triggers"), body: hash_including(
      "name" => "700 - Priradenie podnetu skupine Nižná Agent Smith",
      "condition" => hash_including(
        "ticket.action" => { "operator" => "is", "value" => "create" },
        "ticket.address_municipality" => { "operator" => "is", "value" => [ "Nižná" ] }
      ),
      "perform" => {
        "ticket.group_id" => { "value" => 9 },
        "ticket.owner_id" => { "pre_condition" => "specific", "value" => 3 },
        "ticket.responsible_subject" => { "value" => { "value" => responsible_subject.id, "label" => "Nižná" } }
      }
    )
    assert_requested :post, zammad_url("users"), query: hash_including({}), body: hash_including(
      "email" => "starosta@nizna.sk", "firstname" => "starosta", "lastname" => "Nižná", "organization" => "Nižná",
      "roles" => [ "Externý zodpovedný subjekt" ]
    )
    assert_requested :post, zammad_url("users"), query: hash_including({}), body: hash_including(
      "email" => "jan.novak@nizna.sk", "firstname" => "Jan", "lastname" => "Novak", "organization" => "Nižná", "roles" => [ "Customer" ]
    )
    assert_requested :post, zammad_url("users"), query: hash_including({}), body: hash_including(
      "email" => "podatelna@nizna.sk", "firstname" => "podatelna", "lastname" => "Nižná", "organization" => "Nižná",
      "roles" => [ "Customer" ]
    )

    users = User::ResponsibleSubject.where(responsible_subject: responsible_subject).order(:external_id)
    assert_equal [ [ 59, "starosta@nizna.sk" ], [ 60, "jan.novak@nizna.sk" ], [ 61, "podatelna@nizna.sk" ] ], users.pluck(:external_id, :email)
  end

  test "validate! passes for a new municipality" do
    assert_nothing_raised { build_activation.validate! }
  end

  test "validate! rejects a boundary that is a district or already belongs to a municipality" do
    assert_invalid "only municipality boundaries are supported", boundary_id: municipality_boundaries(:stare_mesto).id
    assert_invalid "already belongs to municipality Trenčín", boundary_id: municipality_boundaries(:trencin).id
    assert_invalid "Municipality boundary \"0\" does not exist", boundary_id: "0"
  end

  test "validate! rejects a municipality or responsible subject that already exists in the portal" do
    assert_invalid "Municipality Vinodol already exists", name: "Vinodol"
    assert_invalid "Responsible subject MÚ Staré Mesto already exists", name: "MÚ Staré Mesto"
  end

  test "validate! rejects a district that does not exist" do
    assert_invalid "District \"Liptovský kraj\" does not exist, use one of: Banskobystrický kraj", district_name: "Liptovský kraj"
    assert_invalid "District \"\" does not exist", district_name: ""
  end

  test "validate! rejects invalid and duplicate emails" do
    assert_invalid "starosta@ is not a valid email address", user_emails: "starosta@, jan.novak@nizna.sk"
    assert_invalid "USERS contains duplicate emails", user_emails: "jan.novak@nizna.sk, Jan.Novak@nizna.sk"
  end

  test "validate! rejects a Triage group, organization or trigger that already exists" do
    stub_zammad(:get, "groups", body: [ { id: 9, name: "Nižná" } ])
    stub_zammad(:get, "organizations/search", body: [ { id: 5, name: "Nižná" } ])
    stub_zammad(:get, "triggers", body: [
      { id: 70, name: "700 - Priradenie podnetu skupine Nižná Iná Agentka",
        condition: { "ticket.address_municipality" => { operator: "is", value: [ "Nižná" ] } } },
      { id: 71, name: "700 - Priradenie podnetu skupine Nižná Myšľa Agent Smith",
        condition: { "ticket.address_municipality" => { operator: "is", value: [ "Nižná Myšľa" ] } } }
    ])

    error = assert_raises(ResponsibleSubjects::BasicActivation::Invalid) { build_activation.validate! }

    assert_includes error.message, "Triage group Nižná already exists"
    assert_includes error.message, "Triage organization Nižná already exists"
    assert_includes error.message, "Triage trigger \"700 - Priradenie podnetu skupine Nižná Iná Agentka\" (70) already exists"
    assert_not_includes error.message, "Nižná Myšľa"
  end

  test "validate! rejects a user that already exists in Triage" do
    stub_zammad(:get, "users/search", body: [ zammad_fixture("zammad/user_organization_member", email: "jan.novak@nizna.sk") ])
      .with(query: hash_including("query" => "jan.novak@nizna.sk"))

    assert_invalid "Triage user jan.novak@nizna.sk already exists (77, organization: \"MÚ Staré Mesto\")"
  end

  test "validate! rejects a user who is already a responsible subject user in the portal" do
    assert_invalid "Portal user nitra@mesto.sk is already a responsible subject user", user_emails: "nitra@mesto.sk, jan.novak@nizna.sk"
  end

  test "validate! rejects missing Triage roles" do
    stub_zammad(:get, "roles", body: [ { id: 8, name: "Portal Tech Account", group_ids: {} } ])

    assert_invalid "Triage role Externý zodpovedný subjekt does not exist"
  end

  test "validate! rejects a Triage user that is not an agent" do
    stub_zammad(:get, "users/search", body: [ zammad_fixture("zammad/user_organization_member") ])
      .with(query: hash_including("query" => "referent@staremesto.sk"))

    assert_invalid "Triage user referent@staremesto.sk (Ján Referent) is not an agent", triage_agent_email: "referent@staremesto.sk"
  end

  test "validate! rejects an agent email that is not in Triage" do
    assert_invalid "Triage agent \"nobody@odkazprestarostu.sk\" does not exist", triage_agent_email: "nobody@odkazprestarostu.sk"
  end

  test "call changes nothing when invalid" do
    assert_no_difference -> { Municipality.count } do
      assert_raises(ResponsibleSubjects::BasicActivation::Invalid) { build_activation(name: "Vinodol").call }
    end

    assert_not_requested :post, zammad_url("users"), query: hash_including({})
  end

  test "call with use_existing_municipality activates the existing inactive municipality and responsible subject" do
    municipality, existing = create_inactive_municipality
    stub_creation

    responsible_subject = nil
    assert_no_difference -> { Municipality.count } => 0, -> { ResponsibleSubject.count } => 0 do
      responsible_subject = build_activation(use_existing_municipality: true, boundary_id: nil, district_name: nil).call
    end

    assert_equal existing, responsible_subject
    assert_predicate municipality.reload, :active?
    assert_predicate responsible_subject, :active?
    assert_not responsible_subject.pro
    assert_equal "starosta@nizna.sk", responsible_subject.email
    assert_equal "58", responsible_subject.external_id
    assert_requested :post, zammad_url("groups"), query: hash_including({}), body: hash_including("name" => "Nižná")
    assert_requested :post, zammad_url("triggers"), body: hash_including(
      "perform" => hash_including("ticket.responsible_subject" => { "value" => { "value" => existing.id, "label" => "Nižná" } })
    )
    assert_equal 3, User::ResponsibleSubject.where(responsible_subject: responsible_subject).count
  end

  test "call with use_existing_municipality links a boundary without a municipality" do
    municipality, = create_inactive_municipality
    municipality_boundaries(:unmatched_municipality).update!(municipality: nil)
    stub_creation

    build_activation(use_existing_municipality: true).call

    assert_equal municipality, municipality_boundaries(:unmatched_municipality).reload.municipality
  end

  test "validate! with use_existing_municipality rejects a missing or active municipality or responsible subject" do
    assert_invalid "Municipality Nižná does not exist, EXISTING_MUNICIPALITY activates only an existing one", use_existing_municipality: true

    municipality, responsible_subject = create_inactive_municipality
    responsible_subject.update!(active: true, external_id: "58")
    municipality.update!(active: true)
    error = assert_raises(ResponsibleSubjects::BasicActivation::Invalid) { build_activation(use_existing_municipality: true).validate! }
    assert_includes error.message, "Municipality Nižná is already active"
    assert_includes error.message, "Responsible subject Nižná is already active"
    assert_includes error.message, "Responsible subject Nižná already has Triage user 58"

    responsible_subject.destroy!
    assert_invalid "Responsible subject Nižná of municipality Nižná does not exist", use_existing_municipality: true
  end

  test "validate! with use_existing_municipality rejects a boundary of another municipality or another district" do
    create_inactive_municipality

    assert_invalid "already belongs to municipality Trenčín", use_existing_municipality: true, boundary_id: municipality_boundaries(:trencin).id
    assert_invalid "Municipality Nižná is in district #{districts(:za_kraj).name}, not Banskobystrický kraj",
      use_existing_municipality: true, district_name: "Banskobystrický kraj"
  end

  test "names_from_email splits meno.priezvisko, otherwise uses the municipality name as the last name" do
    activation = build_activation

    assert_equal({ firstname: "Jan", lastname: "Novak" }, activation.names_from_email("jan.novak@nizna.sk"))
    assert_equal({ firstname: "podatelna", lastname: "Nižná" }, activation.names_from_email("podatelna@nizna.sk"))
    assert_equal({ firstname: "j.n.novak", lastname: "Nižná" }, activation.names_from_email("j.n.novak@nizna.sk"))
  end

  private

  def build_activation(**overrides)
    ResponsibleSubjects::BasicActivation.new(
      boundary_id: municipality_boundaries(:unmatched_municipality).id,
      name: "Nižná",
      district_name: "žilinský kraj",
      user_emails: "starosta@nizna.sk, jan.novak@nizna.sk, podatelna@nizna.sk",
      triage_agent_email: "agent@example.org",
      client: @client,
      **overrides
    )
  end

  # what the dev seeds create, the boundary already matched by municipality_boundaries:import_all
  def create_inactive_municipality
    municipality = Municipality.create!(name: "Nižná", district: districts(:za_kraj), latitude: 48.5, longitude: 17.5, active: false)
    municipality_boundaries(:unmatched_municipality).update!(municipality: municipality)
    responsible_subject = ResponsibleSubject.create!(
      subject_name: "Nižná", email: "nizna@not-existing-domain.com", municipality: municipality,
      responsible_subjects_type: responsible_subjects_types(:city), pro: true, active: false
    )
    [ municipality, responsible_subject ]
  end

  def assert_invalid(message, **overrides)
    error = assert_raises(ResponsibleSubjects::BasicActivation::Invalid) { build_activation(**overrides).validate! }
    assert_includes error.message, message
  end

  # Triage without anything for Nižná yet
  def stub_triage
    stub_zammad(:get, "users/3", fixture: "zammad/user_agent")
    stub_zammad(:get, "email_addresses", body: [ { id: 1, email: "podnety@triaz.odkazprestarostu.sk" } ])
    stub_zammad(:get, "roles", body: [
      { id: 8, name: "Portal Tech Account", group_ids: { "1" => [ "full" ] } },
      { id: 3, name: "Customer", group_ids: {} },
      { id: 7, name: "Externý zodpovedný subjekt", group_ids: {} }
    ])
    stub_zammad(:get, "groups", body: [ { id: 1, name: "Incoming" } ])
    stub_zammad(:get, "organizations/search", body: [])
    stub_zammad(:get, "triggers", body: [])
    stub_zammad(:get, "users/search", body: [])
    stub_zammad(:get, "users/search", body: [ zammad_fixture("zammad/user_agent") ]).with(query: hash_including("query" => "agent@example.org"))
  end

  def stub_creation
    stub_zammad(:post, "users", status: 201, body: { id: 58 }).with(body: hash_including("roles" => [ "Zodpovedný Subjekt" ]))
    stub_zammad(:post, "groups", status: 201, body: { id: 9, name: "Nižná" })
    stub_zammad(:put, "roles/8", body: { id: 8 })
    stub_zammad(:post, "organizations", status: 201, body: { id: 5, name: "Nižná" })
    stub_zammad(:put, "users/3", fixture: "zammad/user_agent")
    stub_zammad(:post, "triggers", status: 201, body: { id: 70 })

    { 59 => "starosta@nizna.sk", 60 => "jan.novak@nizna.sk", 61 => "podatelna@nizna.sk" }.each do |id, email|
      stub_zammad(:post, "users", status: 201, body: { id: id }).with(body: hash_including("email" => email))
      stub_zammad(:get, "users/#{id}", fixture: "zammad/user_organization_member",
        overrides: { id: id, login: email, email: email, organization: "Nižná" })
    end
  end
end
