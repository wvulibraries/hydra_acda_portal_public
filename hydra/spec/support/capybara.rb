# Capybara configuration for feature specs
require 'capybara/rails'
require 'capybara/rspec'

Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 5

# Uncomment if you want to use Selenium/Chrome for JS tests
# Capybara.javascript_driver = :selenium_chrome_headless

RSpec.configure do |config|
  config.before(:each, type: :feature) do
    # Allow external requests for audio files in feature specs
    WebMock.allow_net_connect!(allow_localhost: true, allow: [/dolecollections\.ku\.edu/])
  end

  config.after(:each, type: :feature) do
    WebMock.disable_net_connect!(allow_localhost: true, allow: [/fcrepo/, /solr/, /postgres/, /redis/, /dolecollections\.ku\.edu/])
  end
end
