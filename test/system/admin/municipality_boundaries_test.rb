require "application_system_test_case"

class Admin::MunicipalityBoundariesTest < ApplicationSystemTestCase
  setup do
    @admin = users(:one)
    @original_admin_emails = ENV["ADMIN_EMAILS"]
    ENV["ADMIN_EMAILS"] = @admin.email
  end

  teardown do
    ENV["ADMIN_EMAILS"] = @original_admin_emails
  end

  test "admin filters boundaries by layer, matching and municipality activity" do
    bratislava = municipalities(:bratislava)
    bratislava.update!(active: true)
    trencin = municipalities(:trencin)
    trencin.update!(active: false)
    bratislava_boundary = create_municipality_boundary(municipality: bratislava, center_lat: 48.15, center_lon: 17.1)
    trencin_boundary = create_municipality_boundary(municipality: trencin, center_lat: 48.9, center_lon: 18.04)
    unmatched = create_municipality_boundary(municipality: nil, center_lat: 48.5, center_lon: 17.5)
    district = create_municipality_boundary(municipality: bratislava, district: municipality_districts(:stare_mesto_ba), center_lat: 48.22, center_lon: 17.17, size: 0.02)
    login_as(@admin)

    visit admin_municipality_boundaries_path

    assert_selector "h1", text: "Hranice obcí a mestských častí"
    assert_no_selector "footer"
    %w[kinds_municipality kinds_district matched_matched matched_unmatched active_true active_false].each { assert_checked_field it }
    assert_boundaries count: 4

    find("path.boundary-#{bratislava_boundary.id}").hover

    assert_selector ".leaflet-tooltip", text: "Bratislava"
    assert_selector "path.boundary-#{bratislava_boundary.id}[stroke-width='4']"

    uncheck "active_false"

    assert_no_selector "path.boundary-#{trencin_boundary.id}"
    assert_selector "path.boundary-#{unmatched.id}"
    assert_boundaries count: 3

    uncheck "matched_matched"

    assert_selector "fieldset[disabled]", text: "Aktivita obce"
    assert_selector "path.boundary-#{unmatched.id}"
    assert_boundaries count: 1

    check "matched_matched"
    uncheck "matched_unmatched"
    uncheck "kinds_municipality"

    assert_no_selector "fieldset[disabled]"
    assert_selector "path.boundary-#{district.id}"
    assert_boundaries count: 1

    uncheck "kinds_district"

    assert_boundaries count: 0
  end

  test "admin selects a municipality and a city district in the tree" do
    bratislava = municipalities(:bratislava)
    stare_mesto = municipality_districts(:stare_mesto_ba)
    create_municipality_boundary(municipality: bratislava, center_lat: 48.15, center_lon: 17.1)
    create_municipality_boundary(municipality: bratislava, district: stare_mesto, center_lat: 48.22, center_lon: 17.17, size: 0.02)
    trencin = municipalities(:trencin)
    create_municipality_boundary(municipality: trencin, center_lat: 48.9, center_lon: 18.04)
    login_as(@admin)

    visit admin_municipality_boundaries_path(kinds: [ "municipality" ])

    assert_boundaries count: 2

    find("summary", text: "Obec: Všetky").click
    fill_in "Hľadať obec alebo mestskú časť", with: "trencin"
    check trencin.name

    assert_selector "summary", text: "Obec: #{trencin.name}"
    assert_boundaries count: 1

    fill_in "Hľadať obec alebo mestskú časť", with: "stare mesto"
    check stare_mesto.name

    assert_selector "summary", text: "Obec: #{trencin.name}, #{stare_mesto.name}"
    assert_checked_field "kinds_district"
    # Trenčín, plus Bratislava and its Staré Mesto district
    assert_boundaries count: 3

    find("h1").click

    assert_no_field "Hľadať obec alebo mestskú časť"
  end

  test "admin selects a boundary by clicking on it and sees its details in the panel" do
    bratislava = municipalities(:bratislava)
    bratislava.update!(active: true)
    trencin = municipalities(:trencin)
    trencin.update!(active: false)
    bratislava_boundary = create_municipality_boundary(municipality: bratislava, center_lat: 48.15, center_lon: 17.1)
    trencin_boundary = create_municipality_boundary(municipality: trencin, center_lat: 48.9, center_lon: 18.04)
    login_as(@admin)

    visit admin_municipality_boundaries_path

    assert_no_selector "aside"

    find("path.boundary-#{bratislava_boundary.id}").click
    find("h1").hover

    assert_selector "path.boundary-#{bratislava_boundary.id}[stroke-width='4']"
    within "aside" do
      assert_selector "h2", text: "Bratislava"
      assert_details "Hranica", "ID" => bratislava_boundary.id, "Typ" => "Obec", "Spárovaná" => "áno"
      assert_details "Obec", "ID" => bratislava.id, "Názov" => "Bratislava", "Aktívna" => "áno"
    end

    find("path.boundary-#{trencin_boundary.id}").click
    find("h1").hover

    assert_selector "path.boundary-#{trencin_boundary.id}[stroke-width='4']"
    assert_selector "path.boundary-#{bratislava_boundary.id}[stroke-width='1.5']"
    within "aside" do
      assert_details "Obec", "ID" => trencin.id, "Názov" => trencin.name, "Aktívna" => "nie"
    end

    find("path.boundary-#{trencin_boundary.id}").click
    find("h1").hover

    assert_selector "path.boundary-#{trencin_boundary.id}[stroke-width='1.5']"
    assert_no_selector "aside"

    find("path.boundary-#{bratislava_boundary.id}").click
    assert_selector "aside h2", text: "Bratislava"
    find("body").send_keys(:escape)
    find("h1").hover

    assert_no_selector "aside"
    assert_selector "path.boundary-#{bratislava_boundary.id}[stroke-width='1.5']"

    find("path.boundary-#{bratislava_boundary.id}").click
    within("aside") { click_on "Zavrieť" }

    assert_no_selector "aside"
  end

  test "url reflects the filter and the selected boundary so it can be shared" do
    bratislava = municipalities(:bratislava)
    boundary = create_municipality_boundary(municipality: bratislava, center_lat: 48.15, center_lon: 17.1)
    create_municipality_boundary(municipality: bratislava, district: municipality_districts(:stare_mesto_ba), center_lat: 48.22, center_lon: 17.17, size: 0.02)
    login_as(@admin)

    visit admin_municipality_boundaries_path

    uncheck "kinds_district"
    uncheck "matched_unmatched"

    assert_current_query "kinds" => [ "municipality" ], "matched" => [ "matched" ], "active" => %w[true false]

    find("path.boundary-#{boundary.id}").click

    assert_selector "aside h2", text: "Bratislava"
    assert_current_query "kinds" => [ "municipality" ], "matched" => [ "matched" ], "active" => %w[true false], "boundary" => boundary.id.to_s

    shared_url = current_url
    visit "about:blank"
    visit shared_url

    assert_selector "aside h2", text: "Bratislava"
    assert_selector "path.boundary-#{boundary.id}[stroke-width='4']"
    assert_unchecked_field "kinds_district"
    assert_unchecked_field "matched_unmatched"

    find("body").send_keys(:escape)

    assert_no_selector "aside"
    assert_current_query "kinds" => [ "municipality" ], "matched" => [ "matched" ], "active" => %w[true false]
  end

  test "the map is not available to users who are not admins" do
    login_as(users(:two))

    visit admin_municipality_boundaries_path

    assert_no_selector "h1", text: "Hranice obcí a mestských častí"
    assert_no_selector ".leaflet-container"
  end

  private

  def assert_boundaries(count:)
    if count.zero?
      assert_no_selector ".leaflet-map-pane path.leaflet-interactive"
    else
      assert_selector ".leaflet-map-pane path.leaflet-interactive", count: count
    end
  end

  def assert_current_query(expected)
    assert_equal expected, Rack::Utils.parse_nested_query(URI.parse(current_url).query).transform_keys { it.delete_suffix("[]") }
  end

  def assert_details(section, values)
    list = find("h3", text: section).find(:xpath, "following-sibling::dl[1]")
    values.each do |term, value|
      assert_equal value.to_s, list.find(:xpath, ".//dt[normalize-space()='#{term}']/following-sibling::dd[1]").text
    end
  end
end
