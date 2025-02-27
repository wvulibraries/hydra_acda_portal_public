class ApplicationJob < ActiveJob::Base
  # Retry on Fedora conflicts with exponential backoff
  retry_on Ldp::Conflict, 
    wait: :exponentially_longer, 
    attempts: 5,
    max_delay: 30.seconds

  # Set timeouts using ActiveFedora configuration
  around_perform do |_job, block|
    ActiveFedora::Base.connection_for_pid('temp').with_timeout(
      ENV.fetch('FEDORA_TIMEOUT', 60).to_i
    ) do
      block.call
    end
  end
end
