require "application_system_test_case"
require "test_helpers/issues/drafts_helper"

class Issues::DraftsTest < ApplicationSystemTestCase
  include Issues::DraftsHelper

  setup do
    @user = users(:one)

    stub_json_request(
      :post,
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=",
      body: /checks prompt/,
      response: "webmock/gemini/checks-confirmable.json"
    )

    stub_json_request(
      :post,
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=",
      body: /suggestions prompt/,
      response: "webmock/gemini/suggestions-graffiti.json"
    )

    stub_json_request(
      :get,
      "https://nominatim.openstreetmap.org/reverse?format=json&lat=48.16311388888889&lon=17.049330555555557",
      response: "webmock/nominatim/pusta-reverse.json"
    )

    stub_json_request(
      :get,
      "https://nominatim.openstreetmap.org/details?addressdetails=1&format=json&osmid=25298061&osmtype=W",
      response: "webmock/nominatim/pusta-details.json"
    )
  end

  teardown do
    WebMock.reset!
  end

  test "full issue creation with checks" do
    login_as(@user)

    click_on "Nahlásiť podnet"

    attach_file "issues_draft_photos", "test/fixtures/files/graffiti-with-geo.jpg", visible: false

    assert_text "Lokalita"
    click_on "Pokračovať"

    assert_text "Poškodená rozvodná skriňa"
    assert_text "Popis podnetu"

    click_on "Vlastný nadpis podnetu"

    assert_text "Výber kategórie problému"
    click_on "Zeleň a životné prostredie"

    assert_text "Výber podkategórie problému"
    click_on "Strom"

    assert_text "Výber typu problému"
    click_on "vyvaleny"

    assert_text "Popis podnetu"
    fill_in "Názov", with: "Graffiti na skrini"
    fill_in "Popis", with: "Je tu graffiti, treba vycistit"
    click_on "Pokračovať"

    assert_text "Zhrnutie podnetu"
    click_on "Odoslať podnet"

    assert_text "Podnet má problém"
    click_on "Odoslať podnet aj tak"

    assert_text "Podnet bol odoslaný!"

    click_on "Zobraziť všetky moje podnety"
    assert_text "Graffiti"

    click_on "Sledované podnety"
    assert_text "Legacy issue"
    assert_text "Graffiti"
  end

  test "issue creation continues without suggestions when suggestions prompt is missing" do
    bratislava = municipalities("bratislava")
    karlova_ves = municipality_districts("Karlova Ves")
    create_municipality_boundary(municipality: bratislava, center_lat: 48.1631, center_lon: 17.0493, size: 0.5)
    create_municipality_boundary(municipality: bratislava, district: karlova_ves, center_lat: 48.1631, center_lon: 17.0493, size: 0.1)

    cms_pages(:ai_generate_suggestions).destroy!

    login_as(@user)

    click_on "Nahlásiť podnet"

    attach_file "issues_draft_photos", "test/fixtures/files/graffiti-with-geo.jpg", visible: false

    assert_text "Lokalita"
    click_on "Pokračovať"

    assert_text "Popis podnetu"
    assert_no_text "Z fotografie sme automaticky vytvorili popisy podnetu"
    assert_no_text "Poškodená rozvodná skriňa"

    click_on "Vlastný nadpis podnetu"

    assert_text "Výber kategórie problému"
  end

  test "draft with nearby duplicates shows them and returns to the summary" do
    duplicate = place_duplicate_near_photo_location

    fill_draft_up_to_summary
    click_on "Odoslať podnet"

    assert_text "V blízkosti podnetu sa už nachádzajú duplicitné podnety z rovnakej kategórie."
    click_on "Skontroluj duplicitný podnet"

    assert_text "Podobné alebo duplicitné dopyty"
    assert_text duplicate.title
    assert_text "Máte rozpracovaný podnet. Môžete ho dokončiť tu."

    click_on "Zobraziť podnet"

    assert_text "Zhrnutie podnetu"
    assert_not Issues::Draft.last.duplicates_shown
  end

  test "draft can be finished from the duplicates page" do
    place_duplicate_near_photo_location

    fill_draft_up_to_summary
    click_on "Odoslať podnet"
    click_on "Skontroluj duplicitný podnet"

    assert_text "Podobné alebo duplicitné dopyty"
    assert_no_text "Neodoslaný podnet"
    click_on "Dokončiť podnet"

    assert_text "Podnet má problém"
    click_on "Odoslať podnet aj tak"

    assert_text "Podnet bol odoslaný!"
    assert Issues::Draft.last.submitted
  end

  test "draft with nearby duplicates can be registered as a new issue" do
    place_duplicate_near_photo_location

    fill_draft_up_to_summary
    click_on "Odoslať podnet"

    assert_text "V blízkosti podnetu sa už nachádzajú duplicitné podnety z rovnakej kategórie."
    click_on "Registrovať ako nový podnet"

    assert_text "Podnet má problém"
    click_on "Odoslať podnet aj tak"

    assert_text "Podnet bol odoslaný!"

    draft = Issues::Draft.last
    assert draft.duplicates_shown
    assert draft.submitted
  end

  test "issue creation on unsupported municipality" do
    municipality = municipalities("bratislava")
    municipality.update!(active: false)

    # without the district boundary the point matches only the inactive municipality
    municipality_boundaries(:karlova_ves).destroy!

    login_as(@user)

    click_on "Nahlásiť podnet"

    attach_file "issues_draft_photos", "test/fixtures/files/graffiti-with-geo.jpg", visible: false

    assert_text "Lokalita"
    click_on "Pokračovať"

    assert_text "Poškodená rozvodná skriňa"
    assert_text "Popis podnetu"

    click_on "Vlastný nadpis podnetu"

    assert_text "Samospráva nie je zatiaľ zapojená do portálu Odkaz pre starostu"
  end

  test "issue creation on unsupported municipality district" do
    municipality_district = municipality_districts("Karlova Ves")
    municipality_district.update!(active: false)

    login_as(@user)

    click_on "Nahlásiť podnet"

    attach_file "issues_draft_photos", "test/fixtures/files/graffiti-with-geo.jpg", visible: false

    assert_text "Lokalita"
    click_on "Pokračovať"

    assert_text "Poškodená rozvodná skriňa"
    assert_text "Popis podnetu"

    click_on "Vlastný nadpis podnetu"

    assert_text "Mestská časť nie je zatiaľ zapojená do portálu Odkaz pre starostu"
  end

  test "draft is sent as an update of a duplicate from the popup and removed" do
    duplicate = place_duplicate_near_photo_location

    fill_draft_up_to_summary
    click_on "Odoslať podnet"
    click_on "Skontroluj duplicitný podnet"

    click_on duplicate.title

    within "dialog.duplicate-popup" do
      assert_text "Aktualizovať podnet"
      assert_field "issues_update_text", with: "Je tu graffiti, treba vycistit"
      assert_selector "figure.small-picture img"

      fill_in "issues_update_text", with: "Graffiti je tu stále, pribudlo aj ďalšie."
    end

    assert_enqueued_with(job: Issues::SyncEditableActivityToTriageJob) do
      within("dialog.duplicate-popup") { click_on "Aktualizovať podnet" }

      assert_text "Podnet bol odoslaný ako aktualizácia už existujúceho podnetu"
      within "#activities" do
        assert_text "Graffiti je tu stále, pribudlo aj ďalšie."
      end
    end

    assert_not Issues::Draft.exists?(author: @user, submitted: false)
    assert_text "Nahlásiť podnet"

    update = Issues::Update.last
    assert_equal duplicate, update.activity.issue
    assert_equal 1, update.attachments.count
  end

  test "duplicate update without a photo shows an error in the popup" do
    duplicate = place_duplicate_near_photo_location

    fill_draft_up_to_summary
    click_on "Odoslať podnet"
    click_on "Skontroluj duplicitný podnet"

    click_on duplicate.title

    within "dialog.duplicate-popup" do
      accept_confirm { find("figure.small-picture .close-button").click }
      assert_no_selector "figure.small-picture"

      click_on "Aktualizovať podnet"

      assert_selector ".error-message"
    end

    assert_not Issues::Draft.last.submitted
  end

  private

  def place_duplicate_near_photo_location
    issues(:sent_to_responsible).tap do |issue|
      issue.update_columns(latitude: 48.1632, longitude: 17.0494)

      stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=")
        .with(body: /duplicates prompt/)
        .to_return(
          headers: { "Content-Type" => "application/json" },
          body: { candidates: [ { content: { parts: [ { text: [ issue.id ].to_json } ] } } ] }.to_json
        )
    end
  end

  def fill_draft_up_to_summary
    bratislava = municipalities("bratislava")
    karlova_ves = municipality_districts("Karlova Ves")
    create_municipality_boundary(municipality: bratislava, center_lat: 48.1631, center_lon: 17.0493, size: 0.5)
    create_municipality_boundary(municipality: bratislava, district: karlova_ves, center_lat: 48.1631, center_lon: 17.0493, size: 0.1)

    login_as(@user)

    click_on "Nahlásiť podnet"

    attach_file "issues_draft_photos", "test/fixtures/files/graffiti-with-geo.jpg", visible: false

    assert_text "Lokalita"
    click_on "Pokračovať"

    assert_text "Popis podnetu"
    click_on "Vlastný nadpis podnetu"

    click_on "Zeleň a životné prostredie"
    click_on "Strom"
    click_on "vyvaleny"

    fill_in "Názov", with: "Graffiti na skrini"
    fill_in "Popis", with: "Je tu graffiti, treba vycistit"
    click_on "Pokračovať"

    assert_text "Zhrnutie podnetu"
  end
end
