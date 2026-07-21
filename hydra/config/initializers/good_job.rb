Rails.application.configure do
  config.good_job.poll_interval = 30
  config.good_job.max_threads = ENV.fetch("GOODJOB_MAX_THREADS", 5).to_i
  config.good_job.queues = 'critical:3;default:2;import:1;export:1'
  config.good_job.execution_mode = :external
end