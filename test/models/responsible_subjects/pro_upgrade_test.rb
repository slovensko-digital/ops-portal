require "test_helper"
require "test_helpers/zammad_helper"

class ResponsibleSubjects::ProUpgradeTest < ActiveSupport::TestCase
  include ZammadHelper

  setup do
    @client = ZammadApiClient.new(url: ENV.fetch("TRIAGE_ZAMMAD_URL"), http_token: "token")
    @municipality = Municipality.create!(name: "Nižná", district: districts(:za_kraj), latitude: 48.5, longitude: 17.5, active: true)
    @responsible_subject = ResponsibleSubject.create!(
      subject_name: "Nižná", email: "starosta@nizna.sk", municipality: @municipality,
      responsible_subjects_type: responsible_subjects_types(:city), pro: false, active: true, external_id: "58"
    )
    stub_zammad(:get, "roles", body: [ { id: 3, name: "Customer", group_ids: {} } ])
    stub_basic_setup
  end

  test "call keeps the Triage setup, removes the organization, makes its users citizens and sets the responsible subject PRO" do
    portal_user = User::ResponsibleSubject.create!(
      firstname: "Starosta", lastname: "Nižná", email: "starosta@nizna.sk", external_id: 59, responsible_subject: @responsible_subject,
      status: :verified, onboarded: true, password: SecureRandom.hex(32), phone_verified: true
    )
    log = []

    tenant = build_upgrade(log: ->(message) { log << message }).call

    @responsible_subject.reload
    assert @responsible_subject.pro
    assert_predicate @responsible_subject, :active?
    client = @responsible_subject.clients.sole
    assert_equal client.id, tenant.ops_api_subject_identifier
    assert_equal "http://localhost:8081/", tenant.backoffice_url

    assert_requested :put, zammad_url("users/59"), body: { "organization_id" => nil, "roles" => [ "Customer" ] }
    assert_requested :put, zammad_url("users/60"), body: { "organization_id" => nil, "roles" => [ "Customer" ] }
    assert_requested :delete, zammad_url("organizations/5"), query: hash_including({})
    assert_not_requested :post, zammad_url("users"), query: hash_including({})
    assert_not_requested :post, zammad_url("groups"), query: hash_including({})
    assert_not_requested :post, zammad_url("triggers")
    assert_includes log, "Triage: organization Nižná (5) deleted"

    portal_user = User.find(portal_user.id)
    assert_instance_of User::Citizen, portal_user
    assert_nil portal_user.responsible_subject
  end

  test "organization_changes lists the organization's users and its deletion" do
    assert_equal [
      "Triage: take starosta@nizna.sk (59, Externý zodpovedný subjekt) out of organization Nižná, role Externý zodpovedný subjekt -> Customer",
      "Triage: take jan.novak@nizna.sk (60, Customer) out of organization Nižná",
      "Triage: delete organization Nižná (5)"
    ], build_upgrade.organization_changes
  end

  test "call goes on when Triage refuses to delete the organization" do
    stub_zammad(:delete, "organizations/5", status: 422, body: { error: "Can't delete, object has references." })
    log = []

    build_upgrade(log: ->(message) { log << message }).call

    assert @responsible_subject.reload.pro
    assert log.any? { _1.start_with?("Triage: organization Nižná (5) not deleted, delete it by hand") }
  end

  test "call enables the Client and the Tenant disabled by a downgrade, keeping the Tenant's id" do
    client = Client.create!(name: "Nižná", responsible_subject: @responsible_subject, active: false, url: "https://old.example.com/connector/webhook")
    tenant = Connector::Tenant.create!(name: "Nižná", status: :inactive, ops_api_subject_identifier: client.id, backoffice_url: "https://old.example.com/")
    stub_zammad(:get, "organizations/search", body: [])

    assert_includes build_upgrade.plan, "Portal: enable the disabled Client #{client.id} and Connector::Tenant #{tenant.id} Nižná, " \
      "Backoffice http://localhost:8081/, webhook http://localhost:3000/connector/webhook"
    assert_equal tenant, build_upgrade.call

    assert_predicate client.reload, :active?
    assert_equal "http://localhost:3000/connector/webhook", client.url
    assert_predicate tenant.reload, :active?
    assert_equal "http://localhost:8081/", tenant.backoffice_url
    assert_equal "api-token", tenant.backoffice_api_token
    assert_equal 1, @responsible_subject.clients.count
  end

  test "validate! rejects a missing, inactive or PRO responsible subject and one with an active Client" do
    assert_invalid "Responsible subject Vinodol does not exist, activate it with responsible_subjects:activate_pro", name: "Vinodol"
    assert_invalid "Responsible subject Mesto Malacky is already PRO", name: "Mesto Malacky"

    @responsible_subject.update!(active: false)
    assert_invalid "Responsible subject Nižná is not active, activate it with responsible_subjects:activate_pro"

    @responsible_subject.update!(active: true)
    Client.create!(name: "Nižná", responsible_subject: @responsible_subject)
    assert_invalid "Responsible subject Nižná already has an active Client"
  end

  test "validate! rejects an existing Tenant and invalid arguments" do
    Connector::Tenant.create!(name: "Nižná")

    error = assert_raises(ResponsibleSubjects::ProUpgrade::Invalid) do
      build_upgrade(backoffice_url: "localhost:8081", backoffice_api_token: " ", backoffice_webhook_secret: "").validate!
    end
    assert_includes error.message, "Connector::Tenant Nižná"
    assert_includes error.message, "BACKOFFICE_URL \"localhost:8081\" is not an http(s) URL"
    assert_includes error.message, "BACKOFFICE_API_TOKEN is missing"
    assert_includes error.message, "BACKOFFICE_WEBHOOK_SECRET is missing"
  end

  test "validate! rejects a missing Triage group or trigger" do
    stub_zammad(:get, "groups", body: [ { id: 1, name: "Incoming" } ])
    stub_zammad(:get, "triggers", body: [])

    error = assert_raises(ResponsibleSubjects::ProUpgrade::Invalid) { build_upgrade.validate! }
    assert_includes error.message, "Triage group Nižná does not exist"
    assert_includes error.message, "Triage 700 trigger for Nižná does not exist"
  end

  private

  def build_upgrade(**overrides)
    ResponsibleSubjects::ProUpgrade.new(
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
    error = assert_raises(ResponsibleSubjects::ProUpgrade::Invalid) { build_upgrade(**overrides).validate! }
    assert_includes error.message, message
  end

  # what responsible_subjects:activate_basic leaves in Triage, the organization's users are out of it once updated
  def stub_basic_setup
    stub_zammad(:get, "users/58", fixture: "zammad/user_responsible_subject", overrides: { id: 58, login: "ops-rs-58" })
    stub_zammad(:get, "groups", body: [ { id: 1, name: "Incoming" }, { id: 9, name: "Nižná" } ])
    stub_zammad(:get, "triggers", body: [
      { id: 70, name: "700 - Priradenie podnetu skupine Nižná Agent Smith",
        condition: { "ticket.address_municipality" => { operator: "is", value: [ "Nižná" ] } } }
    ])
    stub_zammad(:get, "organizations/search", body: [ { id: 5, name: "Nižná" } ])
    stub_zammad(:get, "organizations/5", body: { id: 5, name: "Nižná", member_ids: [ 59, 60 ] })
    { 59 => [ "starosta@nizna.sk", "Externý zodpovedný subjekt" ], 60 => [ "jan.novak@nizna.sk", "Customer" ] }.each do |id, (email, role)|
      member = zammad_fixture("zammad/user_organization_member", id: id, login: email, email: email, organization: "Nižná", roles: [ role ])
      stub_request(:get, zammad_url("users/#{id}")).with(query: hash_including({}))
        .to_return(status: 200, body: member.to_json, headers: { "Content-Type" => "application/json" })
        .then.to_return(status: 200, body: member.merge("organization" => nil, "organization_id" => nil, "roles" => [ "Customer" ]).to_json,
          headers: { "Content-Type" => "application/json" })
      stub_zammad(:put, "users/#{id}", body: { id: id })
    end
    stub_zammad(:delete, "organizations/5", body: {})
  end
end
