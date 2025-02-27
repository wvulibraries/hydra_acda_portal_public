class ApplicationJob < ActiveJob::Base
  # Retry on Fedora conflicts with exponential backoff
  retry_on Ldp::Conflict, 
    wait: :exponentially_longer, 
    attempts: 5

  # Set timeouts using ActiveFedora configuration
  around_perform do |_job, block|
    ActiveFedora.fedora.connection.client.options.merge!(
      timeout: ENV.fetch('FEDORA_TIMEOUT', 60).to_i
    )
    block.call
  ensure
    # Reset timeout after job completes
    ActiveFedora.fedora.connection.client.options.merge!(
      timeout: 60
    )
  end

  private

  def retry_delay(attempt)
    # Calculate exponential backoff with a max of 30 seconds
    [2 ** attempt, 30].min.seconds
  end
end
