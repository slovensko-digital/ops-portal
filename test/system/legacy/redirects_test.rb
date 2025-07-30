require "application_system_test_case"

class Legacy::RedirectsTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  test "user gets redirected from municipality legacy root to new root" do
    visit "/r/bratislava"

    assert_current_path "/"
  end

  test "user gets redirected from legacy all issues list to issues path" do
    visit "/r/bratislava/vsetky-podnety"

    assert_current_path issues_path(obec: "Bratislava")
  end

  test "user gets redirected from non-existent legacy municipality all issues list to issues path" do
    visit "/r/non-existent/vsetky-podnety"

    assert_current_path issues_path
  end

  test "user gets redirected from legacy all issues in municipality district to municipality district issues path if exists" do
    visit "/r/bratislava/podnety/stare-mesto"

    assert_current_path issues_path(obec: "Bratislava", cast: "Staré Mesto")
  end

  test "user gets redirected from legacy all issues in municipality district to municipality issues path if municipality district does not exist" do
    visit "/r/bratislava/podnety/neexistujuca-stvrt"

    assert_current_path issues_path(obec: "Bratislava")
  end

  test "user gets redirected from legacy statistics page" do
    visit "/r/bratislava/statistiky"

    assert_current_path issues_path(obec: "Bratislava", tab: "stats")
  end

  test "user gets redirected from legacy issue page to new issue page" do
    visit "/r/bratislava/podnety/12345/any-slug"

    assert_current_path issue_path(issues(:legacy1))
  end

  test "user gets redirected from legacy issue page even with query params to new issue page" do
    visit "/r/bratislava/podnety/12345/any-slug?utm_source=legacy"

    assert_current_path issue_path(issues(:legacy1))
  end

  test "user gets redirected from legacy issue update page to new issue page" do
    visit "/r/bratislava/podnety/12345/any-slug/aktualizovat-podnet"

    assert_current_path issue_path(issues(:legacy1))
  end

  test "user gets redirected from legacy issue creation page to welcome page" do
    visit "/r/bratislava/pridat-podnet"

    assert_current_path cms_page_path("vitajte-na-novom-portali-odkaz-pre-starostu")
  end

  test "legacy visit cookie is set when visiting legacy routes" do
    visit "/r/bratislava"

    visit "/login"

    assert_text "Mali ste účet na pôvodnom portáli Odkaz pre starostu"
  end

  test "user gets redirected from legacy street slug to municipality issues path" do
    visit "/r/trencin/podnety/ulica/1480/viedenska-cesta-stara-cast"

    assert_current_path issues_path(obec: "Trenčín")
  end

  test "user gets redirected from legacy street index to municipality issues path" do
    visit "/r/trencin/podnety/ulica"

    assert_current_path issues_path(obec: "Trenčín")
  end
end
