# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  retry_on Ldp::Conflict,
    wait: :exponentially_longer,
    attempts: 5

  discard_on Ldp::Gone do |job, error|
    Rails.logger.info "Discarding job #{job.class.name} for #{job.arguments.first} - resource no longer exists"

    if job.arguments.first.present?
      record_id = job.arguments.first.to_s
      Rails.logger.info "Cleaning up other GoodJob jobs for #{record_id}"

      GoodJob::Job.where("serialized_params->>'job_class' = ?", job.class.name)
                  .where("serialized_params->'arguments'->>0 = ?", record_id)
                  .where(finished_at: nil)
                  .destroy_all
    end
  end

  rescue_from Ldp::HttpError do |exception|
    Rails.logger.error "Ldp::HttpError in job: #{exception.message}"

    if exception.message.include?('STATUS: 500')
      attempt = executions || 0
      if attempt < 3
        Rails.logger.info "Retrying after Fedora 500 error (attempt #{attempt + 1})"
        retry_job wait: (attempt + 1) * 30.seconds
      else
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
        Rails.logger.error "Max retries reached for Fedora 500 error, giving up"
        raise exception
      end
    else
      raise exception
    end
  end

  def self.already_queued?(id)
    GoodJob::Job.where("serialized_params->>'job_class' = ?", name)
                .where("serialized_params->'arguments'->>0 = ?", id.to_s)
                .where(finished_at: nil)
                .exists?
  end

  def self.perform_once(id, *args)
    return if already_queued?(id)
    perform_later(id, *args)
  end

  def retry_delay(attempt)
    (attempt + 1) ** 2 * 10
  end
end