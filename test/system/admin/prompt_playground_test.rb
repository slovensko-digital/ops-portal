require "application_system_test_case"

class Admin::PromptPlaygroundTest < ApplicationSystemTestCase
  setup do
    @admin = users(:one)
    @original_admin_emails = ENV["ADMIN_EMAILS"]
    ENV["ADMIN_EMAILS"] = @admin.email

    Rails.cache.delete("gemini/models")
    stub_request(:get, %r{generativelanguage\.googleapis\.com/v1beta/models\?}).to_return(
      body: file_fixture("webmock/gemini/models.json").read,
      headers: { "Content-Type" => "application/json" }
    )
  end

  teardown do
    ENV["ADMIN_EMAILS"] = @original_admin_emails
    WebMock.reset!
  end

  test "admin runs the saved test cases against an edited prompt and another model" do
    request_bodies = []
    stub_request(:post, %r{/models/gemini-2\.5-pro:generateContent})
      .with {
        request_bodies << JSON.parse(it.body)
        sleep 0.5 # long enough to see the cases being evaluated
      }
      .to_return(body: file_fixture("webmock/gemini/checks-parking.json").read, headers: { "Content-Type" => "application/json" })
    login_as(@admin)

    visit_playground

    assert_selector "h1", text: "Testovanie promptu na kontrolu podnetov"
    assert_field "Prompt", with: cms_pages(:ai_generate_checks).raw
    assert_no_text "Prompt sa líši od CMS"

    assert_select "Model", selected: "gemini-2.5-flash (produkcia) · 0,30 $ / 2,50 $ za 1M tokenov"

    fill_in "Prompt", with: "edited prompt"
    select "gemini-2.5-pro · 1,25 $ / 10,00 $ za 1M tokenov", from: "Model"
    click_on "Spustiť všetky testy"

    assert_button "Vyhodnocujú sa testy…", disabled: true
    within(test_case(:parking)) { assert_selector ".result-running .spinner" }

    within(test_case(:parking)) { assert_text "✔ Prešiel" }
    within(test_case(:pothole)) do
      assert_text "✘ Neprešiel"
      assert_text "Navyše: Parkovanie"
    end
    assert_text "Prešlo 1 z 2 · cena 0,009 $ · ≈ 4,5 $ za 1 000 podnetov"
    within(test_case(:parking)) { assert_text "2 000 + 200 tokenov · 0,0045 $" }
    assert_text "Prompt sa líši od CMS"
    assert_button "Spustiť všetky testy"
    assert_no_selector ".spinner"
    assert_equal [ "edited prompt" ] * 2, request_bodies.map { it.dig("system_instruction", "parts", 0, "text") }

    refresh

    assert_field "Prompt", with: "edited prompt"
    assert_select "Model", selected: "gemini-2.5-pro · 1,25 $ / 10,00 $ za 1M tokenov"

    click_on "Načítať prompt z CMS"

    within("dialog[open]") do
      assert_text "Zahodiť úpravy promptu?"
      assert_button "Kopírovať prompt"
      click_on "Zrušiť"
    end

    assert_no_selector "dialog[open]"
    assert_field "Prompt", with: "edited prompt"

    click_on "Načítať prompt z CMS"
    within("dialog[open]") { click_on "Zahodiť úpravy a načítať z CMS" }

    assert_no_selector "dialog[open]"
    assert_field "Prompt", with: cms_pages(:ai_generate_checks).raw
    assert_no_text "Prompt sa líši od CMS"

    click_on "Načítať prompt z CMS"

    assert_no_selector "dialog[open]"
  end

  test "admin sees the diff from the CMS prompt only after opening it" do
    login_as(@admin)
    visit_playground

    fill_in "Prompt", with: cms_pages(:ai_generate_checks).raw.sub("Title: Vrak", "Title: Autovrak")

    assert_no_selector ".diff-line"

    find("summary", text: "Zobraziť rozdiel oproti CMS").click

    assert_selector ".diff-del", text: "- Title: Vrak"
    assert_selector ".diff-add", text: "+ Title: Autovrak"
  end

  test "admin copies the edited prompt to paste it into the CMS" do
    login_as(@admin)
    visit_playground
    # headless Chrome has no clipboard access, record what the page writes to it
    execute_script "navigator.clipboard.writeText = async (text) => { window.copiedText = text }"

    fill_in "Prompt", with: "edited prompt\n{{ CATEGORIES_TABLE }}"
    click_on "Kopírovať prompt"

    assert_button "✔ Skopírované"
    assert_equal "edited prompt\n{{ CATEGORIES_TABLE }}", evaluate_script("window.copiedText")
    assert_button "Kopírovať prompt"
  end

  test "admin adds, edits and deletes a test case" do
    login_as(@admin)
    visit_playground

    click_on "+ Pridať testovací prípad"
    click_on "Uložiť"

    assert_text "Názov testovacieho prípadu je povinná položka"

    fill_in "Názov testovacieho prípadu", with: "Vrak pri garážach"
    fill_in "Názov podnetu", with: "Opustené auto"
    fill_in "Popis podnetu", with: "Pri garážach stojí vrak bez ŠPZ."
    fill_in "Adresa", with: "Trenčín, Hviezdoslavova 5"
    check "Vrak"
    fill_in "Ďalšie očakávané kontroly", with: "Nová kontrola"
    click_on "Uložiť"

    assert_selector "article h3", text: "Vrak pri garážach"
    assert_link "+ Pridať testovací prípad"
    test_case = Ai::PromptTestCase.find_by!(name: "Vrak pri garážach")
    assert_equal({ "title" => "Opustené auto", "description" => "Pri garážach stojí vrak bez ŠPZ.", "address" => "Trenčín, Hviezdoslavova 5" }, test_case.input)
    assert_equal [ "Vrak", "Nová kontrola" ], test_case.expected_check_titles

    within(test_case(test_case)) do
      click_on "Upraviť"
      assert_checked_field "Nová kontrola"
      uncheck "Vrak"
      click_on "Uložiť"

      assert_selector "dd", exact_text: "Nová kontrola"
    end
    assert_equal [ "Nová kontrola" ], test_case.reload.expected_check_titles

    accept_confirm { within(test_case(test_case)) { click_on "Zmazať" } }

    assert_no_selector "article h3", text: "Vrak pri garážach"
    assert_not Ai::PromptTestCase.exists?(test_case.id)
  end

  test "the playground is not available to users who are not admins" do
    login_as(users(:two))

    visit admin_prompt_test_cases_path

    assert_no_selector "h1", text: "Testovanie promptu"
  end

  private

  # The edited prompt is kept in localStorage, start every test from the CMS version
  def visit_playground
    visit admin_prompt_test_cases_path
    execute_script "localStorage.clear()"
    refresh
  end

  def test_case(name_or_record)
    record = name_or_record.is_a?(Symbol) ? ai_prompt_test_cases(name_or_record) : name_or_record
    find("##{ActionView::RecordIdentifier.dom_id(record)}")
  end
end
