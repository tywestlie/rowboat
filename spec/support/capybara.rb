require "capybara/rspec"

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-gpu")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :headless_chrome
Capybara.default_driver = :headless_chrome

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :headless_chrome
  end
end
