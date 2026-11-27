require "application_system_test_case"
require "test_helpers/request_helper"

class Issues::DraftsTest < ApplicationSystemTestCase
  include RequestHelper

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
    submit = find_button("Odoslať podnet")
    pause_submission(submit)
    submit.send_keys(:enter)

    pending = find_button("Kontrolujeme podnet…", disabled: true)
    assert_not_equal "none", spinner_animation(pending)
    page.execute_script("arguments[0].click()", pending.native)
    assert_equal 1, page.evaluate_script("window.pendingSubmission.requests")
    page.execute_script("window.pendingSubmission.release()")

    assert_text "Podnet má problém"
    confirmation = find_button("Odoslať podnet aj tak")
    pause_submission(confirmation)
    confirmation.click

    assert_button "Odosielame podnet…", disabled: true
    page.execute_script("window.pendingSubmission.release()")

    assert_text "Podnet bol odoslaný!"

    click_on "Zobraziť všetky moje podnety"
    assert_text "Graffiti"

    click_on "Sledované podnety"
    assert_text "Legacy issue"
    assert_text "Graffiti"
  end

  test "photo that cannot be read is rejected" do
    login_as(@user)

    click_on "Nahlásiť podnet"

    attach_file "issues_draft_photos", file_fixture("not-an-image.png").to_s, visible: false

    assert_text "sú v nepodporovanom formáte."
    assert_not ActiveStorage::Blob.exists?(filename: "not-an-image.png")
  end

  test "photo that cannot be read is rejected when added to an existing draft" do
    login_as(@user)

    click_on "Nahlásiť podnet"
    attach_file "issues_draft_photos", "test/fixtures/files/graffiti-with-geo.jpg", visible: false
    assert_text "Lokalita"

    visit edit_issues_draft_path(@user.issues_drafts.last)
    attach_file "issues_draft_photos", file_fixture("not-an-image.png").to_s, visible: false

    assert_text "sú v nepodporovanom formáte."
    assert_equal [ "graffiti-with-geo.jpg" ], @user.issues_drafts.last.photos.map { |photo| photo.filename.to_s }
  end

  test "failed submission restores the button with reduced motion" do
    draft = @user.issues_drafts.create!(
      category: issues_categories(:one), latitude: 48.16, longitude: 17.05,
      title: "Graffiti na skrini", description: "Je tu graffiti, treba vycistit"
    )
    file_fixture("graffiti-with-geo.jpg").open do |photo|
      draft.photos.attach(io: photo, filename: "graffiti-with-geo.jpg")
    end
    login_as(@user)
    visit issues_draft_summary_path(draft)
    browser = page.driver.browser
    browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-reduced-motion", value: "reduce" } ])

    submit = find_button("Odoslať podnet")
    pause_submission(submit)
    submit.click

    pending = find_button("Kontrolujeme podnet…", disabled: true)
    assert_equal "none", spinner_animation(pending)
    page.execute_script("window.pendingSubmission.reject()")

    assert_button "Odoslať podnet", disabled: false
  ensure
    browser&.execute_cdp("Emulation.setEmulatedMedia", features: [])
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

  test "photo can be dropped onto the upload box" do
    login_as(@user)

    click_on "Nahlásiť podnet"

    find(".report-suggestion-add-pictures-con").drop(file_fixture("graffiti-with-geo.jpg").to_s)

    assert_text "Lokalita"
    assert_equal 1, @user.issues_drafts.last.photos.count
  end

  test "adding a photo to a draft keeps the photos already there" do
    login_as(@user)

    click_on "Nahlásiť podnet"
    attach_file "issues_draft_photos", file_fixture("graffiti-with-geo.jpg").to_s, visible: false
    assert_text "Lokalita"
    click_on "Späť"

    attach_file "issues_draft_photos", file_fixture("avatar.png").to_s, visible: false

    assert_selector ".report-suggestion-pictures-block img", count: 2
    assert_equal [ "avatar.png", "graffiti-with-geo.jpg" ], @user.issues_drafts.last.photos.map { |photo| photo.filename.to_s }.sort
  end

  test "resuming an unfinished draft shows what was filled in and continues with the next step" do
    login_as(@user)
    leave_draft_on_suggestions_step

    visit root_path
    click_on "Neodoslaný podnet"
    click_on "Zobraziť neodoslaný podnet"

    assert_selector "h1", text: "Rozpracovaný podnet"
    assert_selector ".report-summary-edit-pictures img"
    assert_text "Miesto podnetu"
    assert_no_text "Kategória podnetu"
    assert_no_link "Upraviť"
    assert_no_button "Odoslať podnet"

    click_on "Pokračovať"

    assert_text "Poškodená rozvodná skriňa"
    assert_text "Vlastný nadpis podnetu"
  end

  test "unfinished draft with a title but no category continues with the category and can be submitted" do
    stub_json_request(
      :post,
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=",
      body: /checks prompt/,
      response: "webmock/gemini/checks-empty.json"
    )

    login_as(@user)
    leave_draft_on_suggestions_step
    # the state of the drafts that failed on submit in production
    @user.issues_drafts.last.update!(title: "Graffiti na skrini", description: "Je tu graffiti, treba vycistit")

    visit root_path
    click_on "Neodoslaný podnet"
    click_on "Zobraziť neodoslaný podnet"

    assert_selector "h1", text: "Rozpracovaný podnet"
    assert_text "Graffiti na skrini"
    click_on "Pokračovať"

    assert_text "Výber kategórie problému"
    click_on "Zeleň a životné prostredie"
    click_on "Strom"
    click_on "vyvaleny"

    assert_selector "h1", text: "Zhrnutie podnetu"
    assert_text "Graffiti na skrini"
    click_on "Odoslať podnet"

    assert_text "Podnet bol odoslaný!"
    assert_equal "Zeleň a životné prostredie", @user.issues.last.category.name
  end

  test "issue can be submitted anyway when an AI check asks to edit it" do
    stub_json_request(
      :post,
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=",
      body: /checks prompt/,
      response: "webmock/gemini/checks-back.json"
    )

    login_as(@user)
    open_complete_draft_summary

    click_on "Odoslať podnet"

    assert_text "Podnet má problém"
    assert_text "Pitie alkoholu na verejnosti"
    assert_link "Upraviť podnet"
    click_on "Odoslať podnet aj tak"

    assert_text "Podnet bol odoslaný!"
    assert_equal "Graffiti na skrini", @user.issues.last.title
  end

  test "issue is submitted without AI checks when Gemini fails" do
    stub_request(
      :post,
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key="
    ).with(body: /checks prompt/).to_return(status: 500, body: "Internal Server Error")

    login_as(@user)
    open_complete_draft_summary

    click_on "Odoslať podnet"

    assert_text "Podnet bol odoslaný!"
    assert_equal "Graffiti na skrini", @user.issues.last.title
  end

  test "unfinished draft whose photos were all removed continues with the photos" do
    login_as(@user)

    click_on "Nahlásiť podnet"
    attach_file "issues_draft_photos", "test/fixtures/files/graffiti-with-geo.jpg", visible: false
    assert_text "Lokalita"

    click_on "Späť"
    accept_confirm { find(".close-button").click }
    assert_no_selector ".report-summary-edit-pictures img"
    assert_no_link "Pokračovať"

    visit root_path
    click_on "Neodoslaný podnet"
    click_on "Zobraziť neodoslaný podnet"

    assert_selector "h1", text: "Rozpracovaný podnet"
    assert_text "Žiadne fotky"
    click_on "Pokračovať"

    assert_text "Nahrať fotku"
    attach_file "issues_draft_photos", "test/fixtures/files/graffiti-with-geo.jpg", visible: false
    click_on "Pokračovať"

    assert_text "Lokalita"
  end

  test "location step without photos does not fail" do
    login_as(@user)
    draft = @user.issues_drafts.create!

    visit issues_draft_geo_path(draft)

    assert_text "Lokalita"
  end

  private

  def leave_draft_on_suggestions_step
    click_on "Nahlásiť podnet"
    attach_file "issues_draft_photos", "test/fixtures/files/graffiti-with-geo.jpg", visible: false
    assert_text "Lokalita"
    click_on "Pokračovať"
    assert_text "Poškodená rozvodná skriňa"
  end

  def open_complete_draft_summary
    leave_draft_on_suggestions_step
    @user.issues_drafts.last.update!(
      title: "Graffiti na skrini", description: "Je tu graffiti, treba vycistit",
      category: issues_categories(:one), subcategory: issues_subcategories(:one)
    )

    visit root_path
    click_on "Neodoslaný podnet"
    click_on "Zobraziť neodoslaný podnet"
    assert_selector "h1", text: "Zhrnutie podnetu"
  end

  def pause_submission(button)
    page.execute_script(<<~JS, button.native)
      const action = arguments[0].form.action;
      const fetch = window.fetch;
      const pending = window.pendingSubmission = { requests: 0 };

      window.fetch = (url, options) => {
        if (String(url) !== action || options?.method?.toUpperCase() !== "POST") {
          return fetch(url, options);
        }

        pending.requests++;
        return new Promise((resolve, reject) => {
          pending.release = () => {
            window.fetch = fetch;
            resolve(fetch(url, options));
          };
          pending.reject = () => {
            window.fetch = fetch;
            reject(new TypeError("Simulated network failure"));
          };
        });
      };
    JS
  end

  def spinner_animation(button)
    page.evaluate_script("getComputedStyle(arguments[0], '::before').animationName", button.native)
  end
end
