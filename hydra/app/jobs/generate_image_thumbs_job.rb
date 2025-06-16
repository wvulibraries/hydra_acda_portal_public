class GenerateImageThumbsJob < ApplicationJob
  include ImportLibrary

  queue_as :import

  def perform(id, download_path)
    return unless File.exist?(download_path)

    # find record
    record = Acda.where(id: id).first
    return unless record # Guard against deleted records
    
    begin
      # Set up logging
      log_directory = "#{Rails.root}/log/generate_thumbs"
      FileUtils.mkdir_p(log_directory) unless File.exist?(log_directory)
      logger = Logger.new("#{log_directory}/image_thumb_#{id}.log")
      
      # temp folder to store images
      image_path = "/home/hydra/tmp/images"
      thumbnail_path = "/home/hydra/tmp/thumbnails"

      # make folders if they don't exist
      FileUtils.mkdir_p(image_path) unless File.exist?(image_path)
      FileUtils.mkdir_p(thumbnail_path) unless File.exist?(thumbnail_path)

      # add id and extension to image path
      image_path = "#{image_path}/#{id}.jpg"
      
      # moves the already downloaded file to the expected path
      FileUtils.mv(download_path, image_path)
      
      record.files.build unless record.files.present?

      # if image file exists set image file and create thumbnail
      if File.exist?(image_path)
        logger.info "Setting image file for #{id}"
        ImportLibrary.set_file(record.build_image_file, 'application/jpg', image_path)
        
        begin
          logger.info "Creating thumbnail for #{id}"
          MiniMagick::Tool::Convert.new do |convert|
            convert.thumbnail '400x400>'  # Larger size with aspect ratio preservation
            convert.format 'jpg'
            convert.background "white"
            convert.density 300          # Keep high DPI for better quality
            convert.quality 95           # High quality, reasonable file size
            convert << image_path
            convert << "#{thumbnail_path}/#{id}.jpg"
          end
        rescue => e
          logger.error "Failed to create thumbnail: #{e.message}"
        end
      end

      # check and see if thumbnail exists
      if File.exist?("#{thumbnail_path}/#{id}.jpg")
        logger.info "Setting thumbnail file for #{id}"
        ImportLibrary.set_file(record.build_thumbnail_file, 'application/jpg', "#{thumbnail_path}/#{id}.jpg")
      end

      # Mark as completed (using 'completed' instead of 'false' for consistency)
      record.queued_job = 'completed'
      record.save_with_retry!(validate: false)
      logger.info "Successfully saved record with image and/or thumbnail"

      # Only delete files after successful save
      begin
        # delete downloaded image file
        File.delete(image_path) if File.exist?(image_path)

        # delete thumbnails with identifier
        Dir.glob("#{File.dirname(image_path)}/#{id}*").each do |file|
          File.delete(file)
        end

        # delete thumbnails with identifier
        Dir.glob("#{thumbnail_path}/#{id}*").each do |file|
          File.delete(file)
        end
      rescue => e
        logger.error "Error cleaning up files: #{e.message}"
      end
      
    rescue => e
      logger.error "Error in GenerateImageThumbsJob: #{e.message}\n#{e.backtrace.join("\n")}"
      # Mark as error but prevent retry
      record.queued_job = 'error'
      record.save_with_retry!(validate: false)
      raise e
    end
  end
end
