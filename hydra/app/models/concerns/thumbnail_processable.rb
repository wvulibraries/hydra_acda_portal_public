module ThumbnailProcessable
  extend ActiveSupport::Concern

  def should_process_thumbnail?
    return false if dc_type.nil? || ['Sound', 'Moving'].include?(dc_type)
    return false if queued_job.present? && queued_job == 'true'
    
    needs_processing = (
      saved_change_to_preview? ||
      ((saved_change_to_available_by? || saved_change_to_available_at?) && 
        (thumbnail_file.blank? || !image_file.blank?))
    )

    needs_processing && !saved_change_to_thumbnail_file? && !saved_change_to_image_file?
  end

  def needs_thumbnail_download?
    preview.present? && 
    is_active_url?(preview) && 
    (image_file.blank? || saved_change_to_preview?)
  end

  def update_thumbnail_and_image
    return if queued_job == 'true'
    
    Rails.logger.info "Starting update_thumbnail_and_image for #{id}"
    Rails.logger.info "Preview: #{preview}, DC Type: #{dc_type}"
    
    if needs_thumbnail_download?
      Rails.logger.info "Queueing DownloadAndSetThumbsJob for #{id}"
      self.queued_job = 'true'
      save(validate: false)
      DownloadAndSetThumbsJob.perform_later(id)
    else
      Rails.logger.info "No thumbnail job needed for #{id}"
    end
  end

  # Keep only thumbnail-specific methods here
  def saved_change_to_thumbnail_file?
    previous_changes.key?('thumbnail_file')
  end

  def saved_change_to_image_file?
    previous_changes.key?('image_file')
  end
end