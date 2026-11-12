# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
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