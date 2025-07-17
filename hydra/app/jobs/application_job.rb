class ApplicationJob < ActiveJob::Base
  # Retry on Fedora conflicts with exponential backoff
  retry_on Ldp::Conflict, 
    wait: :exponentially_longer, 
    attempts: 5
    
  # Don't retry on Gone errors (resource deleted)
  discard_on Ldp::Gone do |job, error|
    # Log that we're discarding the job due to Gone error
    Rails.logger.info "Discarding job #{job.class.name} for #{job.arguments.first} - resource no longer exists"
    
    # Try to clean up any other jobs for this record to prevent further errors
    if job.arguments.first.present?
      if defined?(Sidekiq)
        record_id = job.arguments.first
        Rails.logger.info "Cleaning up other jobs for #{record_id}"
        
        # Find and delete any other jobs for this ID
        Sidekiq::Queue.all.each do |queue|
          queue.each do |queued_job|
            job_data = queued_job.args.first
            if job_data["arguments"].first == record_id.to_s
              queued_job.delete
              Rails.logger.info "Deleted duplicate job from #{queue.name} queue"
            end
          end
        end
        
        # Check retry set too
        Sidekiq::RetrySet.new.each do |retry_job|
          job_data = retry_job.args.first
          if job_data["arguments"].first == record_id.to_s
            retry_job.delete
            Rails.logger.info "Deleted duplicate job from retry set"
          end
        end
        
        # And scheduled set
        Sidekiq::ScheduledSet.new.each do |scheduled_job|
          job_data = scheduled_job.args.first
          if job_data["arguments"].first == record_id.to_s
            scheduled_job.delete
            Rails.logger.info "Deleted duplicate job from scheduled set"
          end
        end
      end
    end
  end
  
  # More robust error handling for HTTP errors
  rescue_from Ldp::HttpError do |exception|
    Rails.logger.error "Ldp::HttpError in job: #{exception.message}"
    
    # Only retry 500 errors a limited number of times
    if exception.message.include?('STATUS: 500')
      attempt = executions || 0
      if attempt < 3
        Rails.logger.info "Retrying after Fedora 500 error (attempt #{attempt + 1})"
        retry_job wait: (attempt + 1) * 30.seconds
      else
        # Mark record as completed to prevent further retries
        if arguments.first.present?
          begin
            record = Acda.find(arguments.first) rescue nil
            if record && record.respond_to?(:queued_job)
              record.queued_job = 'completed'
              record.save_with_retry!(validate: false) rescue nil
            end
          rescue => e
            Rails.logger.error "Error marking record completed: #{e.message}"
          end
        end
        
        # Then give up
        Rails.logger.error "Max retries reached for Fedora 500 error, giving up"
        raise
      end
    else
      # For other HTTP errors, raise immediately
      raise
    end
  end
  
  # Check if a job of this type is already in the queue for this ID
  def self.already_queued?(id)
    return false unless defined?(Sidekiq)
    
    # Check main queue
    queue_name = self.queue_name.to_s
    queue_jobs = Sidekiq::Queue.new(queue_name).select do |job|
      job_data = job.args.first
      next unless job_data["job_class"] == self.name
      job_data["arguments"].first == id.to_s
    end
    
    # Check retry set
    retry_jobs = Sidekiq::RetrySet.new.select do |job|
      job_data = job.args.first
      next unless job_data["job_class"] == self.name
      job_data["arguments"].first == id.to_s
    end
    
    # Check scheduled set
    scheduled_jobs = Sidekiq::ScheduledSet.new.select do |job|
      job_data = job.args.first
      next unless job_data["job_class"] == self.name
      job_data["arguments"].first == id.to_s
    end
    
    (queue_jobs.size + retry_jobs.size + scheduled_jobs.size) > 0
  end

  # Enhanced perform_once method that also deduplicates existing jobs
  def self.perform_once(id, *args)
    return if already_queued?(id)
    
    # Remove any existing jobs for this ID before queueing a new one
    if defined?(Sidekiq)
      # Find and delete any existing jobs for this ID
      Sidekiq::Queue.all.each do |queue|
        queue.each do |queued_job|
          job_data = queued_job.args.first
          if job_data["arguments"].first == id.to_s && job_data["job_class"] != self.name
            queued_job.delete
            Rails.logger.info "Deleted different job type for #{id} from #{queue.name} queue"
          end
        end
      end
    end
    
    perform_later(id, *args)
  end
  
  # Calculate retry delay with exponential backoff
  def retry_delay(attempt)
    (attempt + 1) ** 2 * 10 # 10, 40, 90, 160, 250 seconds
  end
end
