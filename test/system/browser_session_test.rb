require "application_system_test_case"

class BrowserSessionTest < ApplicationSystemTestCase
  test "reset clears cookies and storage from the previous browser session" do
    visit root_path
    page.execute_script(<<~JS)
      document.cookie = "browser_reset_test=present; path=/";
      localStorage.setItem("browser_reset_test", "present");
      sessionStorage.setItem("browser_reset_test", "present");
    JS

    page.reset!
    visit root_path

    assert_not_includes page.evaluate_script("document.cookie"), "browser_reset_test="
    assert_nil page.evaluate_script("localStorage.getItem('browser_reset_test')")
    assert_nil page.evaluate_script("sessionStorage.getItem('browser_reset_test')")
  end
end
