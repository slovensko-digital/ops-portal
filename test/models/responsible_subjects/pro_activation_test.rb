require "test_helper"
require "test_helpers/zammad_helper"

class ResponsibleSubjects::ProActivationTest < ActiveSupport::TestCase
  include ZammadHelper

  setup do
    @client = ZammadApiClient.new(url: ENV.fetch("TRIAGE_ZAMMAD_URL"), http_token: "token")
    @municipality = Municipality.create!(name: "Nižná", district: districts(:za_kraj), latitude: 48.5, longitude: 17.5, active: true)
    municipality_boundaries(:unmatched_municipality).update!(municipality: @municipality)
    @responsible_subject = ResponsibleSubject.create!(
      subject_name: "Nižná", email: "starosta@nizna.sk", municipality: @municipality,
      responsible_subjects_type: responsible_subjects_types(:city), pro: false, active: true, external_id: "58"
    )
    stub_zammad(:get, "email_addresses", body: [ { id: 1, email: "podnety@triaz.odkazprestarostu.sk" } ])
    stub_zammad(:get, "roles", body: [
      { id: 8, name: "Portal Tech Account", group_ids: { "1" => [ "full" ] } },
      { id: 3, name: "Customer", group_ids: {} }
    ])
    stub_zammad(:get, "users/search", body: [])
    stub_zammad(:get, "users/search", body: [ zammad_fixture("zammad/user_agent") ]).with(query: hash_including("query" => "agent@example.org"))
  end

  test "call on a BASIC responsible subject keeps its Triage setup, removes the organization and activates it as PRO" do
    stub_basic_setup
    log = []

    tenant = build_activation(log: ->(message) { log << message }).call

    @responsible_subject.reload
    assert @responsible_subject.pro
    assert_predicate @responsible_subject, :active?
    assert_equal "58", @responsible_subject.external_id

    client = @responsible_subject.clients.sole
    assert_equal "Nižná", client.name
    assert_equal "http://localhost:3000/connector/webhook", client.url
    assert_equal "Nižná", tenant.name
    assert_equal "http://localhost:8081/", tenant.backoffice_url
    assert_equal [ "api-token", "webhook-secret" ], [ tenant.backoffice_api_token, tenant.backoffice_webhook_secret ]
    assert_equal client.id, tenant.ops_api_subject_identifier
    assert_not tenant.receive_customer_activities
    assert_equal OpenSSL::PKey::EC.new(tenant.ops_api_token_private_key).public_to_pem, client.api_token_public_key
    assert_equal OpenSSL::PKey::EC.new(client.webhook_private_key).public_to_pem, tenant.ops_webhook_public_key

    assert_requested :put, zammad_url("users/59"), body: { "organization_id" => nil, "roles" => [ "Customer" ] }
    assert_requested :put, zammad_url("users/60"), body: { "organization_id" => nil, "roles" => [ "Customer" ] }
    assert_requested :delete, zammad_url("organizations/5"), query: hash_including({})
    assert_not_requested :post, zammad_url("users"), query: hash_including({})
    assert_not_requested :post, zammad_url("groups"), query: hash_including({})
    assert_not_requested :post, zammad_url("triggers")
    assert_includes log, "Triage: organization Nižná (5) deleted"
  end

  test "existing_setup_changes lists the organization's users and its deletion for a BASIC responsible subject" do
    stub_basic_setup

    assert_equal [
      "Triage: take starosta@nizna.sk (59, Externý zodpovedný subjekt) out of organization Nižná, role Externý zodpovedný subjekt -> Customer",
      "Triage: take jan.novak@nizna.sk (60, Customer) out of organization Nižná",
      "Triage: delete organization Nižná (5)"
    ], build_activation.existing_setup_changes
    assert_includes build_activation.plan, "Triage: keep trigger \"700 - Priradenie podnetu skupine Nižná Agent Smith\" (70)"
  end

  test "call on a responsible subject never activated creates its Triage setup and activates it and its municipality" do
    @municipality.update!(active: false)
    @responsible_subject.update!(active: false, external_id: nil)
    stub_zammad(:get, "groups", body: [ { id: 1, name: "Incoming" } ])
    stub_zammad(:get, "triggers", body: [])
    stub_zammad(:get, "organizations/search", body: [])
    stub_zammad(:get, "users/3", fixture: "zammad/user_agent")
    stub_zammad(:post, "users", status: 201, body: { id: 58 })
    stub_zammad(:post, "groups", status: 201, body: { id: 9, name: "Nižná" })
    stub_zammad(:put, "roles/8", body: { id: 8 })
    stub_zammad(:put, "users/3", fixture: "zammad/user_agent")
    stub_zammad(:post, "triggers", status: 201, body: { id: 70 })

    activation = build_activation(triage_agent_email: "agent@example.org")
    assert_empty activation.existing_setup_changes
    activation.call

    assert_predicate @municipality.reload, :active?
    assert_predicate @responsible_subject.reload, :active?
    assert @responsible_subject.pro
    assert_equal "58", @responsible_subject.external_id
    assert_requested :post, zammad_url("users"), query: hash_including({}), body: hash_including("roles" => [ "Zodpovedný Subjekt" ])
    assert_requested :post, zammad_url("groups"), query: hash_including({}), body: hash_including("name" => "Nižná")
    assert_requested :post, zammad_url("triggers"), body: hash_including(
      "name" => "700 - Priradenie podnetu skupine Nižná Agent Smith",
      "perform" => hash_including("ticket.group_id" => { "value" => 9 })
    )
    assert_not_requested :delete, zammad_url("organizations/5"), query: hash_including({})
  end

  test "call goes on when Triage refuses to delete the organization" do
    stub_basic_setup
    stub_zammad(:delete, "organizations/5", status: 422, body: { error: "Can't delete, object has references." })
    log = []

    build_activation(log: ->(message) { log << message }).call

    assert @responsible_subject.reload.pro
    assert log.any? { _1.start_with?("Triage: organization Nižná (5) not deleted, delete it by hand") }
  end

  test "validate! rejects a missing responsible subject, an existing Client or Tenant and invalid arguments" do
    assert_invalid "Responsible subject Vinodol does not exist", name: "Vinodol"
    assert_invalid "Responsible subject Mesto Malacky already has a Client", name: "Mesto Malacky"

    Connector::Tenant.create!(name: "Nižná")
    stub_basic_setup
    error = assert_raises(ResponsibleSubjects::ProActivation::Invalid) do
      build_activation(backoffice_url: "localhost:8081", backoffice_api_token: " ", backoffice_webhook_secret: "").validate!
    end
    assert_includes error.message, "Connector::Tenant Nižná already exists"
    assert_includes error.message, "BACKOFFICE_URL \"localhost:8081\" is not an http(s) URL"
    assert_includes error.message, "BACKOFFICE_API_TOKEN is missing"
    assert_includes error.message, "BACKOFFICE_WEBHOOK_SECRET is missing"
  end

  test "validate! rejects an inactive municipality without a boundary" do
    @municipality.update!(active: false)
    municipality_boundaries(:unmatched_municipality).update!(municipality: nil)

    assert_invalid "Municipality Nižná is inactive and has no boundary"
  end

  test "validate! needs the agent only when the Triage group or trigger is missing" do
    stub_basic_setup
    assert_nothing_raised { build_activation.validate! }

    stub_zammad(:get, "triggers", body: [])
    assert_invalid "Triage agent \"\" does not exist"
  end

  private

  def build_activation(**overrides)
    ResponsibleSubjects::ProActivation.new(
      name: "Nižná",
      backoffice_url: "http://localhost:8081/",
      connector_webhook_url: "http://localhost:3000/connector/webhook",
      backoffice_api_token: "api-token",
      backoffice_webhook_secret: "webhook-secret",
      client: @client,
      **overrides
    )
  end

  def assert_invalid(message, **overrides)
    error = assert_raises(ResponsibleSubjects::ProActivation::Invalid) { build_activation(**overrides).validate! }
    assert_includes error.message, message
  end

  # what responsible_subjects:activate_basic leaves in Triage
  def stub_basic_setup
    stub_zammad(:get, "users/58", fixture: "zammad/user_responsible_subject", overrides: { id: 58, login: "ops-rs-58" })
    stub_zammad(:get, "groups", body: [ { id: 1, name: "Incoming" }, { id: 9, name: "Nižná" } ])
    stub_zammad(:get, "triggers", body: [
      { id: 70, name: "700 - Priradenie podnetu skupine Nižná Agent Smith",
        condition: { "ticket.address_municipality" => { operator: "is", value: [ "Nižná" ] } } }
    ])
    stub_zammad(:get, "organizations/search", body: [ { id: 5, name: "Nižná" } ])
    stub_zammad(:get, "organizations/5", body: { id: 5, name: "Nižná", member_ids: [ 59, 60 ] })
    stub_zammad(:get, "users/59", fixture: "zammad/user_organization_member",
      overrides: { id: 59, login: "starosta@nizna.sk", email: "starosta@nizna.sk", organization: "Nižná", roles: [ "Externý zodpovedný subjekt" ] })
    stub_zammad(:get, "users/60", fixture: "zammad/user_organization_member",
      overrides: { id: 60, login: "jan.novak@nizna.sk", email: "jan.novak@nizna.sk", organization: "Nižná" })
    stub_zammad(:put, "users/59", body: { id: 59 })
    stub_zammad(:put, "users/60", body: { id: 60 })
    stub_zammad(:delete, "organizations/5", body: {})
  end
end
