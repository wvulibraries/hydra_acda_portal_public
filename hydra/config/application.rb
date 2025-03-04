require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Hydra
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Autoload lib/ folder including all subdirectories
    config.autoload_paths << Rails.root.join('lib')

    # use SideKiq by default
    config.active_job.queue_adapter = :sidekiq

    config.asset_pipeline = :propshaft

    config.to_prepare do
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")).sort.each do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      Dir.glob(File.join(File.dirname(__FILE__), "../lib/**/*_decorator*.rb")).sort.each do |c|
        puts c
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.hosts << ".lib.wvu.edu"
  end
end
