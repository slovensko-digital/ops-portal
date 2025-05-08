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

  test "user gets redirected from legacy statistics page" do
    visit "/r/bratislava/statistiky"

    assert_current_path issues_path(obec: "Bratislava", tab: "stats")
  end

  test "user gets redirected from legacy issue page to new issue page" do
    visit "/r/bratislava/podnety/12345/any-slug"

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
end
