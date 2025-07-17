class DownloadAndSetThumbsJob < ApplicationJob
  queue_as :import
  
  retry_on StandardError, wait: :exponentially_longer, attempts: 3 do |job, error|
    Rails.logger.info "Thumbnail download failed after 3 attempts for #{job.arguments.first}, falling back to PDF generation: #{error.message}"
    if record = Acda.where(id: job.arguments.first).first
      # Only reset queued_job if we can't queue the GenerateThumbsJob
      begin
        GenerateThumbsJob.perform_later(record.id)
      rescue StandardError => e
        Rails.logger.error "Failed to queue GenerateThumbsJob for #{record.id}: #{e.message}"
        record.queued_job = 'false'
        record.save!
      end
    else
      Rails.logger.error "Could not find record #{job.arguments.first} to reset queued_job flag"
    end
  end

  def perform(id)
    record = Acda.where(id: id).first
    return unless record # Guard against deleted records
    
    begin
      # Early returns should reset the flag
      return reset_queued_job(record) if record.dc_type.nil?
      return reset_queued_job(record) if ((record.dc_type == 'Sound') || (record.dc_type.include? 'Moving'))
      return unset_image_and_thumbnail!(record) if record.preview.blank?

      file_path = "/home/hydra/tmp/download"
      FileUtils.mkdir_p(file_path) unless File.exist?(file_path)
      download_path = "#{file_path}/#{id}"

      file = URI.open(record.preview)
      tempfile = File.new(download_path, "w+")
      IO.copy_stream(file, download_path)
      tempfile.close

      mime_type = `file --brief --mime-type #{Shellwords.escape(download_path)}`.strip
      return unset_image_and_thumbnail!(record) unless mime_type.include?('image')

      ImportLibrary.set_file(record.build_thumbnail_file, 'application/jpg', "#{download_path}")
      record.queued_job = 'false'
      record.save!

      File.delete(download_path) if File.exist?(download_path)
    rescue StandardError => e
      Rails.logger.error "Error downloading thumbnail for #{record.identifier} (attempt #{executions}): #{e.message}"
      # Don't reset flag here since retry_on will handle it
      raise
    ensure
      # Clean up temp file if it exists
      File.delete(download_path) if File.exist?(download_path)
    end
  end

  private

  def unset_image_and_thumbnail!(record)
    record.thumbnail_file = nil
    record.image_file = nil
    record.queued_job = 'false'
    record.save
    record.update_index
  end

  def reset_queued_job(record)
    record.queued_job = 'false'
    record.save
  end
end

