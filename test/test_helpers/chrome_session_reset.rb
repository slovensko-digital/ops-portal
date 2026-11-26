require "capybara/selenium/driver"
require "capybara/selenium/driver_specializations/chrome_driver"

module ChromeSessionReset
  def reset!
    super
  rescue Selenium::WebDriver::Error::InvalidArgumentError => error
    raise unless error.message.include?("* is not a valid URL")

    # Chrome 158 rejects Capybara's wildcard storage reset. Discard the
    # browser rather than leave cookies or storage behind for the next test.
    quit
  end
end

# Remove when Capybara ships a fix for https://github.com/teamcapybara/capybara/issues/2865.
Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeSessionReset)
