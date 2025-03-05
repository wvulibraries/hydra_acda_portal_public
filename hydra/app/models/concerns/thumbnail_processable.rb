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

  # Keep only thumbnail-specific methods here
  def saved_change_to_thumbnail_file?
    previous_changes.key?('thumbnail_file')
  end

  def saved_change_to_image_file?
    previous_changes.key?('image_file')
  end
end