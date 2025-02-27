class ApplicationJob < ActiveJob::Base
  # Retry on Fedora conflicts with exponential backoff
  retry_on Ldp::Conflict, 
    wait: :exponentially_longer, 
    attempts: 5

  # Set timeouts using ActiveFedora configuration
  around_perform do |_job, block|
    original_timeout = ActiveFedora.fedora.connection.http.read_timeout
    ActiveFedora.fedora.connection.http.read_timeout = ENV.fetch('FEDORA_TIMEOUT', 60).to_i
    
    block.call
  ensure
    # Reset timeout after job completes
    ActiveFedora.fedora.connection.http.read_timeout = original_timeout
  end

  private

  def retry_delay(attempt)
    # Calculate exponential backoff with a max of 30 seconds
    [2 ** attempt, 30].min.seconds
  end
end
