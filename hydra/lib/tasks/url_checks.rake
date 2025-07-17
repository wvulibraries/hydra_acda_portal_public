namespace :url_checks do
  desc "Remove URL check records older than 24 hours"
  task cleanup: :environment do
    deleted_count = UrlCheck.where('last_checked_at < ?', 24.hours.ago).delete_all
    Rails.logger.info "Cleaned up #{deleted_count} old URL check records"
  end
end