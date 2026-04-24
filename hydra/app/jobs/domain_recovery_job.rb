# frozen_string_literal: true

class DomainRecoveryJob < ApplicationJob
  queue_as :default

  sidekiq_options unique: :until_executed

  RETRY_INTERVAL = 10.minutes
  CHECK_TIMEOUT  = 10

  def perform(domain)
    unless still_down?(domain)
      Rails.logger.info "DomainRecoveryJob: #{domain} already cleared, stopping"
      return
    end

    if domain_responds?(domain)
      DomainHealthService.mark_up!(domain)
      Rails.logger.info "DomainRecoveryJob: #{domain} recovered, clearing domain lock"
    else
      Rails.logger.info "DomainRecoveryJob: #{domain} still down, rechecking in #{RETRY_INTERVAL / 60} mins"
      DomainRecoveryJob.set(wait: RETRY_INTERVAL).perform_later(domain)
    end
  end

  private

  def still_down?(domain)
    !DomainHealthService.up?("https://#{domain}")
  end

  def domain_responds?(domain)
    uri = URI.parse("https://#{domain}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = CHECK_TIMEOUT
    http.read_timeout = CHECK_TIMEOUT

    response = http.head('/')
    response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection)
  rescue StandardError => e
    Rails.logger.info "DomainRecoveryJob: #{domain} check failed — #{e.message}"
    false
  end
end