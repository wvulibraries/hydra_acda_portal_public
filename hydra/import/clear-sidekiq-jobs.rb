require 'sidekiq/api'
require 'redis'

# Clear Sidekiq jobs and related data
puts "Clearing Sidekiq RetrySet..."
Sidekiq::RetrySet.new.clear

puts "Clearing Sidekiq ScheduledSet..."
Sidekiq::ScheduledSet.new.clear

puts "Clearing Sidekiq DeadSet..."
Sidekiq::DeadSet.new.clear

puts "Clearing all Sidekiq queues..."
Sidekiq::Queue.all.each(&:clear)

# Resetting Sidekiq stats is redundant since we are clearing the database, but kept for completeness
puts "Resetting Sidekiq stats..."
Sidekiq::Stats.new.reset

# Clear Redis (if used exclusively for Sidekiq)
puts "Flushing Redis database..."
redis = Redis.new(url: ENV['REDIS_URL_SIDEKIQ'])
redis.flushdb

puts "Sidekiq and Redis clearing completed."

