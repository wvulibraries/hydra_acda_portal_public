class ApplicationJob < ActiveJob::Base
  # Retry on Fedora conflicts with exponential backoff
  retry_on Ldp::Conflict, 
    wait: :exponentially_longer, 
    attempts: 5

  # Set timeouts using ActiveFedora configuration
  around_perform do |_job, block|
    connection = ActiveFedora.fedora.connection.http
    original_options = connection.options.dup
    
    # Set timeout options
    connection.options.timeout = ENV.fetch('FEDORA_TIMEOUT', 60).to_i
    connection.options.open_timeout = ENV.fetch('FEDORA_TIMEOUT', 60).to_i
    
    block.call
  ensure
    # Reset timeout options after job completes
    connection.options.timeout = original_options.timeout
    connection.options.open_timeout = original_options.open_timeout
  end

  private

  def retry_delay(attempt)
    # Calculate exponential backoff with a max of 30 seconds
    [2 ** attempt, 30].min.seconds
  end
end
