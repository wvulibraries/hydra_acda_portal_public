# https://gist.github.com/wbotelhos/fb865fba2b4f3518c8e533c7487d5354
# script has sh on the end but it's not a shell script changed it to rb

require 'sidekiq/api'
require 'redis'

# 1. Clear retry set

Sidekiq::RetrySet.new.clear

# 2. Clear scheduled jobs 

Sidekiq::ScheduledSet.new.clear

# 3. Clear 'Processed' and 'Failed' jobs

Sidekiq::Stats.new.reset

# 3. Clear 'Dead' jobs statistics

Sidekiq::DeadSet.new.clear

# Stats

stats = Sidekiq::Stats.new
stats.queues
# {"production_mailers"=>25, "production_default"=>1}

# Queue

queue = Sidekiq::Queue.new('default')
puts "Queue count: #{queue.count}"
queue.clear
queue.each { |job| puts job.item } # hash content

# Redis Access
redis = Redis.new(url: ENV['REDIS_URL_SIDEKIQ'])
begin
  puts redis.keys('*')
rescue => e
  puts "An error occurred: #{e.message}"
end

Sidekiq.redis do |conn|
  begin
    puts conn.keys('*')
  rescue => e
    puts "An error occurred: #{e.message}"
  end
end