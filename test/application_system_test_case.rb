require "test_helper"
require "test_helpers/auth_helper"
require "capybara"

Capybara.register_driver :selenium_chrome_no_password_warning do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: Selenium::WebDriver::Options.chrome.tap do |options|
      # Other options removed for clarity
      options.add_preference("profile.password_manager_leak_detection", false)

      options.add_argument("--disable-search-engine-choice-screen")
      options.add_argument("--headless") # comment this line if you want to see the browser
      options.add_argument("--disable-gpu") if Gem.win_platform?
      options.add_argument("--window-size=1400,1400") # has to be set like this, GitHub CI has some own custom
    end
  )
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium_chrome_no_password_warning

  include ActiveJob::TestHelper
  include AuthHelper
end
