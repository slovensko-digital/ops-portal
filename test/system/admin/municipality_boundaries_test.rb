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

  test "admin filters boundaries by kind, match and municipality activity" do
    bratislava = municipalities(:bratislava)
    bratislava.update!(active: true)
    municipality = create_municipality_boundary(municipality: bratislava, center_lat: 48.15, center_lon: 17.1)
    unmatched = create_municipality_boundary(municipality: nil, center_lat: 48.9, center_lon: 18.04)
    create_municipality_boundary(municipality: bratislava, district: municipality_districts(:stare_mesto_ba), center_lat: 48.15, center_lon: 17.1, size: 0.02)
    login_as(@admin)

    visit admin_municipality_boundaries_path

    assert_selector "h1", text: "Hranice obcí a mestských častí"
    assert_no_selector "footer"
    assert_selector "summary", text: "Hranice: Obce"
    assert_boundaries count: 2

    find("path.boundary-#{municipality.id}").hover

    assert_selector ".leaflet-tooltip", text: "Bratislava"
    assert_selector "path.boundary-#{municipality.id}[stroke-width='4']"

    find("summary", text: "Hranice: Obce").click

    assert_checked_field "boundaries_municipality"
    assert_unchecked_field "boundaries_district"

    check "boundaries_district"

    assert_checked_field "boundaries_district_active"
    assert_selector "summary", text: "Hranice: Obce, Mestské časti"
    assert_boundaries count: 3

    uncheck "boundaries_municipality_unmatched"

    assert_selector "summary", text: "Hranice: Obce › Spárované, Mestské časti"
    assert_no_selector "path.boundary-#{unmatched.id}"
    assert_boundaries count: 2

    check "boundaries_municipality"

    assert_checked_field "boundaries_municipality_unmatched"
    assert_selector "summary", text: "Hranice: Obce, Mestské časti"
    assert_boundaries count: 3

    uncheck "boundaries_municipality"

    assert_selector "summary", text: "Hranice: Mestské časti"
    assert_boundaries count: 1

    uncheck "boundaries_district_active"

    assert_selector "summary", text: "Hranice: Mestské časti › Spárované › Neaktívne, Mestské časti › Nespárované"
    assert_boundaries count: 0

    check "boundaries_district_matched"

    assert_checked_field "boundaries_district_active"
    assert_boundaries count: 1

    uncheck "boundaries_district"

    assert_selector "summary", text: "Hranice: Žiadne"
    assert_boundaries count: 0
  end

  test "admin selects a municipality in the tree" do
    bratislava = municipalities(:bratislava)
    stare_mesto = municipality_districts(:stare_mesto_ba)
    create_municipality_boundary(municipality: bratislava, center_lat: 48.15, center_lon: 17.1)
    create_municipality_boundary(municipality: bratislava, district: stare_mesto, center_lat: 48.15, center_lon: 17.1, size: 0.02)
    create_municipality_boundary(municipality: municipalities(:trencin), center_lat: 48.9, center_lon: 18.04)
    login_as(@admin)

    visit admin_municipality_boundaries_path

    assert_selector ".leaflet-overlay-pane path.leaflet-interactive", count: 2

    find("summary", text: "Obec: Všetky").click
    fill_in "Hľadať obec alebo mestskú časť", with: "stare mesto"
    check stare_mesto.name

    assert_selector "summary", text: "Obec: #{stare_mesto.name}"
    assert_selector ".leaflet-overlay-pane path.leaflet-interactive", count: 1

    find("h1").click

    assert_no_field "Hľadať obec alebo mestskú časť"

    find("summary", text: "Hranice: Obce").click
    check "Mestské časti"

    assert_selector ".leaflet-overlay-pane path.leaflet-interactive", count: 2
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

    assert_no_selector "aside"
    assert_selector "path.boundary-#{bratislava_boundary.id}[stroke-width='1.5']"

    find("path.boundary-#{bratislava_boundary.id}").click
    within("aside") { click_on "Zavrieť" }

    assert_no_selector "aside"
  end

  test "panel shows an unmatched boundary" do
    boundary = create_municipality_boundary(municipality: nil, center_lat: 48.15, center_lon: 17.1)
    login_as(@admin)

    visit admin_municipality_boundaries_path
    find("path.boundary-#{boundary.id}").click

    within "aside" do
      assert_selector "h2", text: "Nespárovaná hranica"
      assert_details "Hranica", "ID" => boundary.id, "Spárovaná" => "nie"
      assert_text "Hranica nie je spárovaná so žiadnou obcou."
    end
  end

  private

  def assert_boundaries(count:)
    if count.zero?
      assert_no_selector ".leaflet-overlay-pane path.leaflet-interactive"
    else
      assert_selector ".leaflet-overlay-pane path.leaflet-interactive", count: count
    end
  end

  def assert_details(section, values)
    list = find("h3", text: section).find(:xpath, "following-sibling::dl[1]")
    values.each do |term, value|
      assert_equal value.to_s, list.find(:xpath, ".//dt[normalize-space()='#{term}']/following-sibling::dd[1]").text
    end
  end
end
