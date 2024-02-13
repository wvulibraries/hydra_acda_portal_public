Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL_SIDEKIQ") { "redis://redis:6379/12" } }
  schedule_file = "config/schedule.yml"
  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end
  config.logger.level = Logger.const_get(ENV.fetch('LOG_LEVEL', 'info').upcase.to_s)
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL_SIDEKIQ") { "redis://redis:6379/12" } }
end