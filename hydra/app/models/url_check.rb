class UrlCheck < ApplicationRecord
    validates :url, presence: true, uniqueness: true
    
    # Define enum for status
    enum status: {
      pending: 'pending',
      checking: 'checking',
      complete: 'complete',
      error: 'error'
    }, _default: 'pending'
    
    def needs_recheck?
      return true if last_checked_at.nil?
      return true if error? && retry_count < 3
      last_checked_at < 24.hours.ago
    end
    
    def mark_checking!
      update(
        status: :checking,
        retry_count: retry_count + 1
      )
    end
    
    def mark_complete!(is_active)
      update(
        status: :complete,
        active: is_active,
        last_checked_at: Time.current,
        error_message: nil
      )
    end
    
    def mark_error!(message)
      update(
        status: :error,
        error_message: message
      )
    end
  end