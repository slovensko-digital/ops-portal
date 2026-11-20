require "test_helper"
require "test_helpers/zammad_helper"

class ResponsibleSubjects::ProActivationTest < ActiveSupport::TestCase
  include ZammadHelper

  setup do
    @client = ZammadApiClient.new(url: ENV.fetch("TRIAGE_ZAMMAD_URL"), http_token: "token")
    stub_triage
  end

  test "call creates the municipality, the responsible subject, their Triage setup without an organization and the Backoffice connection" do
    stub_creation

    tenant = build_activation.call

    municipality = Municipality.find_by!(name: "Nižná")
    assert_predicate municipality, :active?
    assert_equal districts(:za_kraj), municipality.district
    assert_equal municipality, municipality_boundaries(:unmatched_municipality).reload.municipality

    responsible_subject = ResponsibleSubject.find_by!(subject_name: "Nižná")
    assert_predicate responsible_subject, :active?
    assert responsible_subject.pro
    assert_nil responsible_subject.email
    assert_equal "58", responsible_subject.external_id

    client = responsible_subject.clients.sole
    assert_predicate client, :active?
    assert_equal "http://localhost:3000/connector/webhook", client.url
    assert_predicate tenant, :active?
    assert_equal "Nižná", tenant.name
    assert_equal "http://localhost:8081/", tenant.backoffice_url
    assert_equal [ "api-token", "webhook-secret" ], [ tenant.backoffice_api_token, tenant.backoffice_webhook_secret ]
    assert_equal client.id, tenant.ops_api_subject_identifier
    assert_equal OpenSSL::PKey::EC.new(tenant.ops_api_token_private_key).public_to_pem, client.api_token_public_key
    assert_equal OpenSSL::PKey::EC.new(client.webhook_private_key).public_to_pem, tenant.ops_webhook_public_key

    assert_requested :post, zammad_url("users"), query: hash_including({}), body: hash_including("roles" => [ "Zodpovedný Subjekt" ])
    assert_requested :post, zammad_url("groups"), query: hash_including({}), body: hash_including("name" => "Nižná")
    assert_requested :post, zammad_url("triggers"), body: hash_including(
      "name" => "700 - Priradenie podnetu skupine Nižná Agent Smith",
      "perform" => hash_including("ticket.group_id" => { "value" => "9" })
    )
    assert_not_requested :post, zammad_url("organizations"), query: hash_including({})
    assert_requested :post, zammad_url("users"), query: hash_including({}), times: 1
  end

  test "call with use_existing_municipality activates the existing inactive municipality and responsible subject as PRO" do
    municipality = Municipality.create!(name: "Nižná", district: districts(:za_kraj), latitude: 48.5, longitude: 17.5, active: false)
    municipality_boundaries(:unmatched_municipality).update!(municipality: municipality)
    existing = ResponsibleSubject.create!(
      subject_name: "Nižná", email: "nizna@not-existing-domain.com", municipality: municipality,
      responsible_subjects_type: responsible_subjects_types(:city), pro: false, active: false
    )
    stub_creation

    assert_no_difference -> { ResponsibleSubject.count } do
      build_activation(use_existing_municipality: true, boundary_id: nil, district_name: nil).call
    end

    assert_predicate municipality.reload, :active?
    assert_predicate existing.reload, :active?
    assert existing.pro
    assert_equal 1, existing.clients.count
  end

  test "validate! rejects a Triage group, organization or trigger that already exists" do
    stub_zammad(:get, "groups", body: [ { id: 9, name: "Nižná" } ])
    stub_zammad(:get, "organizations/search", body: [ { id: 5, name: "Nižná" } ])
    stub_zammad(:get, "triggers", body: [
      { id: 70, name: "700 - Priradenie podnetu skupine Nižná Agent Smith",
        condition: { "ticket.address_municipality" => { operator: "is", value: [ "Nižná" ] } } }
    ])

    error = assert_raises(ResponsibleSubjects::ProActivation::Invalid) { build_activation.validate! }

    assert_includes error.message, "Triage group Nižná already exists"
    assert_includes error.message, "Triage organization Nižná already exists"
    assert_includes error.message, "Triage trigger \"700 - Priradenie podnetu skupine Nižná Agent Smith\" (70) already exists"
  end

  test "validate! points an active BASIC responsible subject to upgrade_to_pro" do
    responsible_subject = responsible_subjects(:pro)
    responsible_subject.update!(pro: false)

    assert_invalid "Responsible subject Mesto Malacky is active as BASIC, make it PRO with responsible_subjects:upgrade_to_pro", name: "Mesto Malacky"
  end

  test "validate! rejects an existing Tenant, invalid URLs and a missing token or secret" do
    Connector::Tenant.create!(name: "Nižná")

    error = assert_raises(ResponsibleSubjects::ProActivation::Invalid) do
      build_activation(backoffice_url: "localhost:8081", backoffice_api_token: " ", backoffice_webhook_secret: "").validate!
    end

    assert_includes error.message, "Connector::Tenant Nižná"
    assert_includes error.message, "BACKOFFICE_URL \"localhost:8081\" is not an http(s) URL"
    assert_includes error.message, "BACKOFFICE_API_TOKEN is missing"
    assert_includes error.message, "BACKOFFICE_WEBHOOK_SECRET is missing"
  end

  test "validate! rejects a missing agent" do
    assert_invalid "Triage agent \"nobody@odkazprestarostu.sk\" does not exist", triage_agent_email: "nobody@odkazprestarostu.sk"
  end

  private

  def build_activation(**overrides)
    ResponsibleSubjects::ProActivation.new(
      boundary_id: municipality_boundaries(:unmatched_municipality).id,
      name: "Nižná",
      district_name: "žilinský kraj",
      triage_agent_email: "agent@example.org",
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

  # Triage without anything for Nižná yet
  def stub_triage
    stub_zammad(:get, "users/3", fixture: "zammad/user_agent")
    stub_zammad(:get, "email_addresses", body: [ { id: 1, email: "podnety@triaz.odkazprestarostu.sk" } ])
    stub_zammad(:get, "roles", body: [ { id: 8, name: "Portal Tech Account", group_ids: { "1" => [ "full" ] } } ])
    stub_zammad(:get, "groups", body: [ { id: 1, name: "Incoming" } ])
    stub_zammad(:get, "organizations/search", body: [])
    stub_zammad(:get, "triggers", body: [])
    stub_zammad(:get, "users/search", body: [])
    stub_zammad(:get, "users/search", body: [ zammad_fixture("zammad/user_agent") ]).with(query: hash_including("query" => "agent@example.org"))
  end

  def stub_creation
    stub_zammad(:post, "users", status: 201, body: { id: 58 })
    stub_zammad(:post, "groups", status: 201, body: { id: 9, name: "Nižná" })
    stub_zammad(:put, "roles/8", body: { id: 8 })
    stub_zammad(:put, "users/3", fixture: "zammad/user_agent")
    stub_zammad(:post, "triggers", status: 201, body: { id: 70 })
  end
end
