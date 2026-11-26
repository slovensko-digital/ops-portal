require "application_system_test_case"

class Admin::MunicipalityBoundariesTest < ApplicationSystemTestCase
  ALL_BOUNDARIES = %i[
    bratislava trencin banska_bystrica unmatched_municipality
    stare_mesto ruzinov karlova_ves bratislava_unmatched_district
  ].freeze

  setup do
    @admin = users(:one)
    @original_admin_emails = ENV["ADMIN_EMAILS"]
    ENV["ADMIN_EMAILS"] = @admin.email
  end

  teardown do
    ENV["ADMIN_EMAILS"] = @original_admin_emails
  end

  test "admin filters boundaries by layer, matching and municipality activity" do
    municipalities(:trencin).update!(active: false)
    login_as(@admin)

    visit admin_municipality_boundaries_path

    assert_selector "h1", text: "Hranice obcí a mestských častí"
    assert_no_selector "footer"
    %w[kinds_municipality kinds_district matched_matched matched_unmatched active_true active_false].each { assert_checked_field it }
    assert_boundaries ALL_BOUNDARIES

    boundary_path(:trencin).hover

    assert_selector ".leaflet-tooltip", text: "Trenčín"
    assert_equal "4px", evaluate_script("getComputedStyle(document.querySelector('path.boundary-#{municipality_boundaries(:trencin).id}')).strokeWidth")

    uncheck "active_false"

    assert_boundaries ALL_BOUNDARIES - %i[trencin]

    uncheck "matched_matched"

    assert_selector "fieldset[disabled]", text: "Aktivita obce"
    assert_boundaries %i[unmatched_municipality bratislava_unmatched_district]

    check "matched_matched"
    uncheck "matched_unmatched"
    uncheck "kinds_municipality"

    assert_no_selector "fieldset[disabled]"
    assert_boundaries %i[stare_mesto ruzinov karlova_ves]

    uncheck "kinds_district"

    assert_boundaries []
  end

  test "admin selects a municipality with its city districts in the tree" do
    bratislava = municipalities(:bratislava)
    ruzinov = municipality_districts(:Ružinov)
    login_as(@admin)

    visit admin_municipality_boundaries_path(kinds: [ "municipality" ])

    assert_boundaries %i[bratislava trencin banska_bystrica unmatched_municipality]

    find("summary", text: "Obec: Všetky").click
    check "municipality_ids_#{bratislava.id}"

    bratislava.municipality_districts.where(id: MunicipalityBoundary.select(:municipality_district_id)).each do |district|
      assert_checked_field "municipality_district_ids_#{district.id}"
    end
    assert_checked_field "kinds_district"
    assert_selector "summary", text: "Obec: Bratislava"
    assert_boundaries %i[bratislava stare_mesto ruzinov karlova_ves bratislava_unmatched_district]

    uncheck "municipality_district_ids_#{ruzinov.id}"

    assert_selector "summary", text: "Obec: Karlova Ves, Staré Mesto"
    assert evaluate_script("document.getElementById('municipality_ids_#{bratislava.id}').indeterminate")
    assert_boundaries %i[bratislava stare_mesto karlova_ves]

    fill_in "Hľadať obec alebo mestskú časť", with: "trencin"
    check "Trenčín"

    assert_selector "summary", text: "Obec: Karlova Ves, Staré Mesto, Trenčín"
    assert_boundaries %i[bratislava stare_mesto karlova_ves trencin]

    find("h1").click

    assert_no_field "Hľadať obec alebo mestskú časť"
  end

  test "admin selects a boundary by clicking on it and sees its details in the panel" do
    banska_bystrica = municipalities(:banska_bystrica)
    trencin = municipalities(:trencin)
    trencin.update!(active: false)
    login_as(@admin)

    visit admin_municipality_boundaries_path

    assert_no_selector "aside"

    boundary_path(:banska_bystrica).click

    assert_selected :banska_bystrica
    within "aside" do
      assert_selector "h2", text: banska_bystrica.name
      assert_details "Hranica", "ID" => municipality_boundaries(:banska_bystrica).id, "Typ" => "Obec", "Spárovaná" => "áno"
      assert_details "Obec", "ID" => banska_bystrica.id, "Názov" => banska_bystrica.name, "Aktívna" => "áno"
    end

    boundary_path(:trencin).click

    assert_selected :trencin
    assert_not_selected :banska_bystrica
    within "aside" do
      assert_details "Obec", "ID" => trencin.id, "Názov" => trencin.name, "Aktívna" => "nie"
    end

    boundary_path(:trencin).click

    assert_not_selected :trencin
    assert_no_selector "aside"

    boundary_path(:banska_bystrica).click
    assert_selector "aside h2", text: banska_bystrica.name
    find("body").send_keys(:escape)

    assert_no_selector "aside"
    assert_not_selected :banska_bystrica

    boundary_path(:banska_bystrica).click
    within("aside") { click_on "Zavrieť" }

    assert_no_selector "aside"
  end

  test "url reflects the filter and the selected boundary so it can be shared" do
    boundary = municipality_boundaries(:bratislava)
    login_as(@admin)

    visit admin_municipality_boundaries_path

    uncheck "kinds_district"
    uncheck "matched_unmatched"

    assert_current_query "kinds" => [ "municipality" ], "matched" => [ "matched" ], "active" => %w[true false]

    boundary_path(:bratislava).click

    assert_selector "aside h2", text: "Bratislava"
    assert_current_query "kinds" => [ "municipality" ], "matched" => [ "matched" ], "active" => %w[true false], "boundary" => boundary.id.to_s

    shared_url = current_url
    visit "about:blank"
    visit shared_url

    assert_selector "aside h2", text: "Bratislava"
    assert_selected :bratislava
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

  # exactly these boundary fixtures are drawn on the map
  def assert_boundaries(names)
    names.each { assert_selector "path.boundary-#{municipality_boundaries(it).id}" }
    if names.empty?
      assert_no_selector ".leaflet-map-pane path.leaflet-interactive"
    else
      assert_selector ".leaflet-map-pane path.leaflet-interactive", count: names.size
    end
  end

  def boundary_path(name)
    find("path.boundary-#{municipality_boundaries(name).id}")
  end

  def assert_selected(name)
    assert_selector "path.boundary-#{municipality_boundaries(name).id}.selected-boundary"
  end

  def assert_not_selected(name)
    assert_selector "path.boundary-#{municipality_boundaries(name).id}:not(.selected-boundary)"
  end

  def assert_current_query(expected)
    query = Rack::Utils.parse_nested_query(URI.parse(current_url).query)
    assert_equal expected, query.transform_keys { it.delete_suffix("[]") }.transform_values { it.is_a?(Array) ? it.compact_blank : it }
  end

  def assert_details(section, values)
    list = find("h3", text: section).find(:xpath, "following-sibling::dl[1]")
    values.each do |term, value|
      assert_equal value.to_s, list.find(:xpath, ".//dt[normalize-space()='#{term}']/following-sibling::dd[1]").text
    end
  end
end
