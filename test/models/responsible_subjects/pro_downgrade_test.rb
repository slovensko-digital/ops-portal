require "test_helper"
require "test_helpers/zammad_helper"

class ResponsibleSubjects::ProDowngradeTest < ActiveSupport::TestCase
  include ZammadHelper

  setup do
    @client = ZammadApiClient.new(url: ENV.fetch("TRIAGE_ZAMMAD_URL"), http_token: "token")
    @responsible_subject = responsible_subjects(:pro)
    @backoffice_client = clients(:pro_backoffice)
    @tenant = Connector::Tenant.create!(name: "Mesto Malacky", ops_api_subject_identifier: @backoffice_client.id)
    stub_pro_setup
  end

  test "call creates the organization with its users, an existing Triage user joins it, and disables the Backoffice connection" do
    stub_creation
    citizen = User::Citizen.create!(
      firstname: "Podatelna", lastname: "Malacky", email: "podatelna@malacky.sk", external_id: 59,
      status: :verified, onboarded: true, password: SecureRandom.hex(32), phone_verified: true
    )

    build_downgrade.call

    @responsible_subject.reload
    assert_not @responsible_subject.pro
    assert_predicate @responsible_subject, :active?
    assert_equal "podatelna@malacky.sk", @responsible_subject.email
    assert_not @backoffice_client.reload.active?
    assert_predicate @tenant.reload, :inactive?

    assert_requested :post, zammad_url("organizations"), query: hash_including({}), body: hash_including("name" => "Mesto Malacky")
    assert_requested :put, zammad_url("users/59"), body: { "organization_id" => 5, "roles" => [ "Portal User", "Externý zodpovedný subjekt" ] }
    assert_requested :post, zammad_url("users"), query: hash_including({}), body: hash_including(
      "email" => "jan.novak@malacky.sk", "organization" => "Mesto Malacky", "roles" => [ "Customer" ]
    )
    assert_not_requested :post, zammad_url("groups"), query: hash_including({})
    assert_not_requested :post, zammad_url("triggers")

    assert_equal @responsible_subject, User.find(citizen.id).responsible_subject
    assert_equal [ "jan.novak@malacky.sk", "podatelna@malacky.sk" ],
      User::ResponsibleSubject.where(responsible_subject: @responsible_subject).order(:email).pluck(:email)
  end

  test "plan lists the users, the disabled connection and the new email" do
    assert_equal [
      "Triage: keep responsible subject user 4242, group Mesto Malacky and the 700 trigger",
      "Triage: create organization Mesto Malacky",
      "Triage and portal: add existing user podatelna@malacky.sk (59, Customer, Portal User) to organization Mesto Malacky, Externý zodpovedný subjekt",
      "Triage and portal: create user jan.novak@malacky.sk to organization Mesto Malacky, Customer",
      "Portal: disable Client #{@backoffice_client.id} and Connector::Tenant #{@tenant.id}",
      "Portal: set responsible subject #{@responsible_subject.id} BASIC, email podatelna@malacky.sk"
    ], build_downgrade.plan
  end

  test "validate! rejects a missing, BASIC or not connected responsible subject" do
    assert_invalid "Responsible subject Vinodol does not exist", name: "Vinodol"

    @backoffice_client.update!(active: false)
    assert_invalid "Responsible subject Mesto Malacky has no active Client"

    @responsible_subject.update!(pro: false)
    assert_invalid "Responsible subject Mesto Malacky is not PRO"
  end

  test "validate! rejects an existing organization, a user in an organization and a user of another responsible subject" do
    stub_zammad(:get, "organizations/search", body: [ { id: 5, name: "Mesto Malacky" } ])
    stub_zammad(:get, "users/search", body: [
      zammad_fixture("zammad/user_organization_member", id: 59, email: "podatelna@malacky.sk", organization: "Mesto Pezinok")
    ]).with(query: hash_including("query" => "podatelna@malacky.sk"))

    error = assert_raises(ResponsibleSubjects::ProDowngrade::Invalid) { build_downgrade.validate! }
    assert_includes error.message, "Triage organization Mesto Malacky already exists"
    assert_includes error.message, "Triage user podatelna@malacky.sk (59) is in organization Mesto Pezinok"

    assert_invalid "Portal user nitra@mesto.sk is a user of responsible subject", user_emails: "nitra@mesto.sk"
  end

  test "validate! rejects missing users and a missing Triage group or trigger" do
    assert_invalid "USERS is missing", user_emails: ""

    stub_zammad(:get, "groups", body: [ { id: 1, name: "Incoming" } ])
    stub_zammad(:get, "triggers", body: [])
    error = assert_raises(ResponsibleSubjects::ProDowngrade::Invalid) { build_downgrade.validate! }
    assert_includes error.message, "Triage group Mesto Malacky does not exist"
    assert_includes error.message, "Triage 700 trigger for Mesto Malacky does not exist"
  end

  private

  def build_downgrade(**overrides)
    ResponsibleSubjects::ProDowngrade.new(
      name: "Mesto Malacky",
      user_emails: "podatelna@malacky.sk, jan.novak@malacky.sk",
      client: @client,
      **overrides
    )
  end

  def assert_invalid(message, **overrides)
    error = assert_raises(ResponsibleSubjects::ProDowngrade::Invalid) { build_downgrade(**overrides).validate! }
    assert_includes error.message, message
  end

  # what responsible_subjects:upgrade_to_pro leaves in Triage: no organization, its former user a customer
  def stub_pro_setup
    stub_zammad(:get, "roles", body: [
      { id: 3, name: "Customer", group_ids: {} },
      { id: 7, name: "Externý zodpovedný subjekt", group_ids: {} }
    ])
    stub_zammad(:get, "groups", body: [ { id: 1, name: "Incoming" }, { id: 9, name: "Mesto Malacky" } ])
    stub_zammad(:get, "triggers", body: [
      { id: 70, name: "700 - Priradenie podnetu skupine Mesto Malacky Agent Smith",
        condition: { "ticket.address_municipality" => { operator: "is", value: [ "Mesto Malacky" ] } } }
    ])
    stub_zammad(:get, "organizations/search", body: [])
    stub_zammad(:get, "users/search", body: [])
    stub_zammad(:get, "users/search", body: [
      zammad_fixture("zammad/user_organization_member", id: 59, login: "podatelna@malacky.sk", email: "podatelna@malacky.sk",
        organization: nil, organization_id: nil, roles: [ "Customer", "Portal User" ])
    ]).with(query: hash_including("query" => "podatelna@malacky.sk"))
  end

  def stub_creation
    stub_zammad(:post, "organizations", status: 201, body: { id: 5, name: "Mesto Malacky" })
    stub_zammad(:put, "users/59", body: { id: 59 })
    stub_zammad(:post, "users", status: 201, body: { id: 61 })
    { 59 => "podatelna@malacky.sk", 61 => "jan.novak@malacky.sk" }.each do |id, email|
      stub_zammad(:get, "users/#{id}", fixture: "zammad/user_organization_member",
        overrides: { id: id, login: email, email: email, organization: "Mesto Malacky" })
    end
  end
end
