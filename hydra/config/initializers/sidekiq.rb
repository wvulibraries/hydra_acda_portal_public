Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL_SIDEKIQ'] }
  schedule_file = "config/schedule.yml"
  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end
  config.logger.level = Logger.const_get(ENV.fetch('LOG_LEVEL', 'info').upcase.to_s)
  
  # Enable client middleware for uniqueness
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL_SIDEKIQ'] }
  
  # Enable client middleware for uniqueness
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end