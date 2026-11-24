require "application_system_test_case"

class Issues::SearchTest < ApplicationSystemTestCase
  setup do
    @bratislava = issues(:two)          # Bratislava, in progress, category one
    @nitra = issues(:sent_to_responsible)
    @nitra.update_columns(municipality_id: municipalities(:Nitra).id, responsible_subject_id: responsible_subjects(:two).id, state_id: issues_states(:referred).id)
    @private = issues(:resolved_private)
  end

  test "list shows publicly visible issues only" do
    visit issues_path

    assert_text @bratislava.title
    assert_text @nitra.title
    assert_no_text @private.title
    assert_no_text issues(:one).title # waiting
  end

  test "filter by municipality" do
    visit issues_path(obec: "Nitra")

    assert_text @nitra.title
    assert_no_text @bratislava.title
  end

  test "filter by lokalita tree combines municipalities and districts" do
    petrzalka_issue = issues(:two)
    petrzalka_issue.update_columns(municipality_district_id: municipality_districts(:Petržalka).id)

    ruzinov_issue = issues(:legacy_discussion_closed)
    ruzinov_issue.update_columns(municipality_district_id: municipality_districts(:Ružinov).id)

    visit issues_path(lokalita: [ "Nitra", "Bratislava-Petržalka" ])

    assert_text @nitra.title
    assert_text petrzalka_issue.title
    assert_no_text ruzinov_issue.title
    assert_no_text @private.title
  end

  test "lokalita filter unticking a district of a selected municipality keeps its other districts" do
    petrzalka_issue = issues(:two)
    petrzalka_issue.update_columns(municipality_district_id: municipality_districts(:Petržalka).id)

    ruzinov_issue = issues(:legacy_discussion_closed)
    ruzinov_issue.update_columns(municipality_district_id: municipality_districts(:Ružinov).id)

    visit issues_path(lokalita: [ "Bratislava" ])
    select_from_search "Ružinov", from: "Obec / Mestská časť"

    assert_selector "li.partial", exact_text: "Bratislava", visible: :all
    assert_no_selector ".filter-select-button", exact_text: "Bratislava"
    assert_text petrzalka_issue.title
    assert_no_text ruzinov_issue.title

    select_from_search "Ružinov", from: "Obec / Mestská časť"

    assert_selector ".filter-select-button", exact_text: "Bratislava"
    assert_text ruzinov_issue.title
  end

  test "lokalita filter search shows a matching district under its municipality" do
    visit issues_path
    fill_in "Obec / Mestská časť", with: "Petržalka"

    within(".dropdown-list") do
      assert_selector "li", exact_text: "Bratislava"
      assert_selector "li", exact_text: "Petržalka"
      assert_no_selector "li", exact_text: "Ružinov"
      assert_no_selector "li", exact_text: "Nitra"
    end
  end

  test "lokalita filter search shows a message when nothing matches and closes on escape" do
    visit issues_path
    input = find_field("Obec / Mestská časť")
    input.fill_in(with: "xyzq")

    assert_text "Nič sme nenašli."

    input.send_keys(:escape)

    assert_no_text "Nič sme nenašli."
    assert_no_selector "li", exact_text: "Bratislava"
  end

  test "lokalita filter list closes on a click outside" do
    visit issues_path
    find_field("Obec / Mestská časť").click

    assert_selector "li", exact_text: "Bratislava"

    find(".filter-title").click

    assert_no_selector "li", exact_text: "Bratislava"
  end

  test "zodpovedny subjekt list closes on escape" do
    visit issues_path
    input = find_field("Zodpovedný subjekt")
    input.fill_in(with: "BVS")

    assert_selector "li", text: "BVS"

    input.send_keys(:escape)

    assert_no_selector "li", text: "BVS"
    assert_equal "", input.value
  end

  test "zodpovedny subjekt search shows a message when nothing matches" do
    visit issues_path
    input = find_field("Zodpovedný subjekt")
    input.fill_in(with: "xyzq")

    assert_text "Nič sme nenašli."

    input.fill_in(with: "BVS")

    assert_no_text "Nič sme nenašli."
    assert_selector "li", text: "BVS"
  end

  test "zodpovedny subjekt list closes on a click outside" do
    visit issues_path
    find_field("Zodpovedný subjekt").click

    assert_selector "li", text: "BVS"

    find(".filter-title").click

    assert_no_selector "li", text: "BVS"
  end

  test "stav podnetu list closes on escape and on a click outside" do
    visit issues_path
    open_stav = -> { find("label", exact_text: "Stav podnetu").sibling(".dropdown-button").click }

    open_stav.call
    assert_selector "li", exact_text: "Odstúpený"

    find("body").send_keys(:escape)
    assert_no_selector "li", exact_text: "Odstúpený"

    open_stav.call
    assert_selector "li", exact_text: "Odstúpený"

    find(".filter-title").click
    assert_no_selector "li", exact_text: "Odstúpený"
  end

  test "filter by responsible subject and by state" do
    visit issues_path(zodpovedny: "BVS")
    assert_text @nitra.title
    assert_no_text @bratislava.title

    visit issues_path(stav: "Odstúpený")
    assert_text @nitra.title
    assert_no_text @bratislava.title
  end

  test "filter by type of request" do
    visit issues_path(dopyt: "Pochvala")

    assert_text issues(:praise_published).title
    assert_no_text @bratislava.title
  end

  test "text search keeps every selected place" do
    visit issues_path(lokalita: [ "Nitra", "Bratislava" ])

    fill_in "Textové vyhľadávanie", with: "Ticket#R-#{@nitra.id}\n"

    assert_current_path(/q=/)
    assert_text @nitra.title
    assert_selector "a[title='Odstrániť tento filter']", exact_text: "Nitra"
    assert_selector "a[title='Odstrániť tento filter']", exact_text: "Bratislava"
  end

  test "fulltext search and search by ticket number" do
    visit issues_path(q: "Bratislava")
    assert_text @bratislava.title
    assert_no_text @nitra.title

    visit issues_path(q: "Ticket#R-#{@nitra.id}")
    assert_text @nitra.title
    assert_no_text @bratislava.title
  end

  test "logged in user can narrow the list to own and to followed issues" do
    user = users(:legacy_citizen)
    @bratislava.update_columns(author_id: user.id)
    user.subscribe_to(issues(:legacy1))
    login_as user

    visit issues_path(zobrazit: "Moje dopyty")
    assert_text @bratislava.title
    assert_no_text issues(:legacy1).title

    visit issues_path(zobrazit: "Sledované dopyty")
    assert_text issues(:legacy1).title
    assert_no_text @bratislava.title
  end

  test "sorting by popularity puts the most liked issue first" do
    @nitra.update_columns(likes_count: 5)

    visit issues_path(sort: "oblubene")

    assert_operator page.text.index(@nitra.title), :<, page.text.index(@bratislava.title)
  end

  test "stats tab shows counts" do
    visit issues_path(tab: "stats")

    assert_text "V riešení"
    assert_text "Odstúpený"
  end

  test "clicking my location again turns the distance filter off" do
    @bratislava.update_columns(latitude: 48.1440, longitude: 17.1090)
    @nitra.update_columns(latitude: 48.3069, longitude: 18.0869)

    visit issues_path(pin: "48.1440,17.1090")
    assert_text @bratislava.title
    assert_no_text @nitra.title

    click_on "Moja poloha"

    assert_text @nitra.title
    assert_no_current_path(/pin=/)
  end

  test "filter links keep the current tab" do
    visit issues_path(tab: "stats", obec: "Nitra")

    assert_includes find("a[title='Odstrániť tento filter']", visible: :all)[:href], "tab=stats"
  end

  test "filter and sort links drop the current page" do
    visit issues_path(page: 2, obec: "Nitra")

    assert_selector "a[title='Odstrániť tento filter']", visible: :all
    assert_no_selector "a[href*='page=']:not(nav.pagination a), input[name='page'], [data-geolocate-url-value*='page=']", visible: :all
  end
end
