class DownloadAndSetThumbsJob < ApplicationJob
  queue_as :import
  
  # Add sidekiq options for uniqueness
  # include Sidekiq::Worker
  # sidekiq_options queue: 'import', 
  #                 unique: :until_executed,
  #                 unique_expiration: 24.hours.to_i,
  #                 retry: 3

  retry_on OpenURI::HTTPError, wait: :exponentially_longer, attempts: 3
  retry_on Errno::ENOENT, wait: :exponentially_longer, attempts: 3

  def perform(id)
    # Add lock check
    lock_key = "download_thumbs_#{id}"
    return if Rails.cache.exist?(lock_key)
    
    begin
      Rails.cache.write(lock_key, true, expires_in: 1.hour)
      
      # Existing perform logic
      record = Acda.where(id: id).first
      return unless record # Early return if record not found
      
      # Ignore if record type is sound or moving image
      return if record.dc_type.nil?
      return if ((record.dc_type == 'Sound') || (record.dc_type.include? 'Moving'))
      return unset_image_and_thumbnail!(record) if record.preview.blank?

      process_preview(record, id)
    ensure
      Rails.cache.delete(lock_key)
    end
  end

  private

  def process_preview(record, id)
    file_path = setup_download_directory
    download_path = "#{file_path}/#{id}"

    begin
      download_and_process_file(record, download_path)
    rescue OpenURI::HTTPError => e
      Rails.logger.error "HTTP Error downloading preview for #{record.identifier}: #{e.message}"
      unset_image_and_thumbnail!(record)
    rescue Errno::ENOENT => e
      Rails.logger.error "File Error for #{record.identifier}: #{e.message}"
      unset_image_and_thumbnail!(record)
    rescue StandardError => e
      Rails.logger.error "Unexpected error for #{record.identifier}: #{e.message}"
      unset_image_and_thumbnail!(record)
    ensure
      # Always try to clean up the temporary file
      File.delete(download_path) if File.exist?(download_path)
    end
  end

  def setup_download_directory
    file_path = "/home/hydra/tmp/download"
    FileUtils.mkdir_p(file_path)
    file_path
  end

  def download_and_process_file(record, download_path)
    # Download file with timeout
    download_with_timeout(record.preview, download_path)

    # Validate downloaded file
    validate_downloaded_file(download_path)

    # Process the file
    ImportLibrary.set_file(record.build_thumbnail_file, 'application/jpg', download_path)
    record.save!
  end

  def download_with_timeout(url, download_path)
    Timeout.timeout(30) do
      file = URI.open(url)
      IO.copy_stream(file, download_path)
    end
  rescue Timeout::Error => e
    Rails.logger.error "Timeout downloading file"
    raise Errno::ENOENT.new("Timeout downloading file")
  end

  def validate_downloaded_file(download_path)
    unless File.exist?(download_path) && File.size(download_path) > 0
      raise Errno::ENOENT.new("Downloaded file is empty or missing")
    end

    mime_type = `file --brief --mime-type #{Shellwords.escape(download_path)}`.strip
    unless mime_type.include?('image')
      File.delete(download_path)
      raise Errno::ENOENT.new("Downloaded file is not an image")
    end
  end

  def unset_image_and_thumbnail!(record)
    record.thumbnail_file = nil
    record.image_file = nil
    record.save
    record.update_index
  rescue StandardError => e
    Rails.logger.error "Error unsetting image/thumbnail for #{record.identifier}: #{e.message}"
  end
end
