class DownloadDlgImageJob < ApplicationJob
  include ImportLibrary
  queue_as :import

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(id)
    record = Acda.where(id: id).first
    return unless record # Guard against deleted records

    begin
      return reset_queued_job(record) if record.available_at.blank?

      # Set up temp file path
      file_path = "/home/hydra/tmp/download"
      FileUtils.mkdir_p(file_path) unless File.exist?(file_path)
      download_path = "#{file_path}/#{id}_full"

      # Extract record ID from available_at URL
      record_id = record.identifier
      iiif_url = "https://dlg.usg.edu/images/iiif/2/dlg%2Fgych%2Frbrl001%2F#{record_id}%2F#{record_id}-00001.jp2/full/max/0/default.jpg"

      # Download full image
      file = URI.open(iiif_url)
      IO.copy_stream(file, download_path)
      
      # Verify it's an image
      mime_type = `file --brief --mime-type #{Shellwords.escape(download_path)}`.strip
      if mime_type.include?('image')
        # Save full image to Fedora
        ImportLibrary.set_file(record.build_image_file, mime_type, download_path)
        
        # Update record type since we confirmed it's an image
        record.dc_type = "Image"
        record.queued_job = 'false'
        record.save!
        
        # Queue thumbnail generation from full image
        GenerateImageThumbsJob.perform_later(id, download_path)
      else
        unset_image_and_reset!(record)
      end

    rescue StandardError => e
      Rails.logger.error "Error downloading DLG image for #{record.identifier}: #{e.message}"
      raise
    ensure
      # Clean up temp file
      File.delete(download_path) if File.exist?(download_path)
    end
  end

  private

  def unset_image_and_reset!(record)
    record.image_file = nil
    record.queued_job = 'false'
    record.save!
  end

  def reset_queued_job(record)
    record.queued_job = 'false'
    record.save!
  end
end