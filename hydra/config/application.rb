require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Hydra
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Add these performance optimizations
    config.cache_classes = true
    config.eager_load = true
    config.autoloader = :zeitwerk  # Use the newer autoloader
      
    # Autoload lib/ folder including all subdirectories
    config.autoload_paths << Rails.root.join('lib')

    # use SideKiq by default
    config.active_job.queue_adapter = :sidekiq

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

    # Following two lines only needed to test direct access by IP, bypassing nginx proxy:
    require "ipaddr"
    config.hosts << IPAddr.new("157.182.150.0/24")
    
    config.hosts << ".lib.wvu.edu"
    config.hosts << "congressarchives.org"

    # Add this line to use the new connection handling
    config.active_record.legacy_connection_handling = false
  end
end
