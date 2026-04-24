# frozen_string_literal: true

class DomainHealthService
  REDIS_KEY_PREFIX = 'domain_down:'.freeze
  FLAP_THRESHOLD   = 15
  FLAP_WINDOW_TTL  = 15.minutes
  FLAP_LOCK_TTL    = 1.hour

  def self.up?(url)
    return true if url.blank?
    domain = extract_domain(url)
    return true if domain.blank?

    Sidekiq.redis { |r| r.get("#{REDIS_KEY_PREFIX}#{domain}") }.nil?
  end

  def self.mark_down!(url)
    domain = extract_domain(url)
    return if domain.blank?

    flap_key = "domain_failed_urls:#{domain}"

    Sidekiq.redis do |r|
      r.sadd(flap_key, [url])            # Set add
      r.expire(flap_key, FLAP_WINDOW_TTL.to_i)
    end

    unique_failures = Sidekiq.redis { |r| r.scard(flap_key) }         # counts set cardinality - no of unique brokem URLs

    if unique_failures >= FLAP_THRESHOLD
      locked = Sidekiq.redis { |r| r.setnx("#{REDIS_KEY_PREFIX}#{domain}", Time.current.to_s) }
      if locked
        Sidekiq.redis { |r| r.expire("#{REDIS_KEY_PREFIX}#{domain}", FLAP_LOCK_TTL.to_i) }
        Rails.logger.warn "DomainHealthService: #{domain} — #{unique_failures} unique URLs failed in #{FLAP_WINDOW_TTL / 60} mins, locking for #{FLAP_LOCK_TTL / 60} mins"
      end
      return
    end

    written = Sidekiq.redis { |r| r.setnx("#{REDIS_KEY_PREFIX}#{domain}", Time.current.to_s) }
    if written
      Rails.logger.warn "DomainHealthService: #{domain} marked DOWN (#{unique_failures} unique URL failures)"
      DomainRecoveryJob.perform_later(domain)
    end
  end

  def self.mark_up!(domain)
    Sidekiq.redis { |r| r.del("#{REDIS_KEY_PREFIX}#{domain}") }
    Rails.logger.info "DomainHealthService: #{domain} is back UP"
  end

  def self.all_down_domains
    Sidekiq.redis do |r|
      keys = r.keys("#{REDIS_KEY_PREFIX}*")
      keys.map { |k| k.sub(REDIS_KEY_PREFIX, '') }
    end
  end

  def self.extract_domain(url)
    URI.parse(url).host
  rescue URI::InvalidURIError
    nil
  end
end