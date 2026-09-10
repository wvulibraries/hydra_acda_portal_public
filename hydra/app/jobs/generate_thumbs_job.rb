class GenerateThumbsJob < ApplicationJob
  queue_as :import

  FILE_EXTENSIONS = %w[.jpg .jpeg .png .gif .pdf].freeze

  def perform(id)
    record = Acda.where(id: id).first
    unless record # Guard against deleted records
      Rails.logger.error "Record #{id} not found, marking job as completed"
      return
    end
    
    begin
      # Set up logging
      log_directory = "#{Rails.root}/log/generate_thumbs"
      FileUtils.mkdir_p(log_directory) unless File.exist?(log_directory)
      logger = Logger.new("#{log_directory}/thumbnail_#{id}.log")

      # Special case for videos - handle differently
      if record.dc_type == "Moving" || record.dc_type == "MovingImage" || 
         (record.available_by&.include?('vimeo.com') || record.available_at&.include?('vimeo.com'))
        logger.info "Video/Vimeo content detected, extracting thumbnail"
        success = handle_video_thumbnail(record, logger)
        if success
          logger.info "Successfully processed video thumbnail"
          record.queued_job = 'completed'
          record.save_with_retry!(validate: false)
          return
        else
          # Create a default thumbnail if we couldn't extract one
          logger.info "Failed to extract thumbnail, creating default"
          create_default_video_thumbnail(record, "#{Rails.root}/tmp/downloads/#{id}", logger)
          record.queued_job = 'completed'
          record.save_with_retry!(validate: false)
          return
        end
      end

      # Early returns for unsupported types
      if record.dc_type.nil? || ['Sound', 'Moving'].include?(record.dc_type)
        logger.info "Skipping unsupported type: #{record.dc_type}"
        record.queued_job = 'completed'  # Mark as completed
        record.save_with_retry!(validate: false)
        return
      end

      download_path = "#{Rails.root}/tmp/downloads/#{id}"
      FileUtils.mkdir_p(File.dirname(download_path)) unless File.exist?(File.dirname(download_path))

      success = false
      # Clear URL selection logic
      if record.available_by.present?
        logger.info "Using available_by for download: #{record.available_by}"
        success = process_url(record.available_by, download_path, logger)
      elsif record.available_at.present?
        logger.info "Using available_at for external resource: #{record.available_at}"
        success = process_url(record.available_at, download_path, logger)
      end

      if success && File.exist?(download_path) && File.size(download_path) > 0
        handle_downloaded_file(record, download_path, logger)
      else
        # If we can't download a file, mark as completed to prevent retries
        logger.error "No file was successfully downloaded for #{id}"
        record.queued_job = 'completed'
        record.save_with_retry!(validate: false)
      end
    rescue => e
      logger.error "Error in GenerateThumbsJob for #{id}: #{e.message}\n#{e.backtrace.join("\n")}"
      # Always mark as completed to prevent infinite retries
      record.queued_job = 'completed'
      record.save_with_retry!(validate: false)
      raise e
    end
  end

  private

  # Process the URL based on whether it's a direct file or an embedded file
  def process_url(url, download_path, logger)
    if direct_file?(url)
      logger.info "Direct file link detected: #{url}"
      download_resource(url, download_path, logger)
    else
      logger.info "Attempting to extract embedded file from URL: #{url}"
      extract_and_download_embedded_file(url, download_path, logger)
    end
  end

  EMBEDDED_FILE_LINK_SELECTOR = 'a.new-primary[href]'.freeze

  # Extract and download embedded file from webpage
  def extract_and_download_embedded_file(url, download_path, logger)
    require 'nokogiri'
    require 'open-uri'

    begin
      logger.info "Fetching webpage: #{url}"
      # replaced any | with %7C
      url = url.gsub('|', '%7C')
      
      html = URI.open(url).read
      doc = Nokogiri::HTML(html)

      # Locate the embedded file download link
      embedded_url = doc.css(EMBEDDED_FILE_LINK_SELECTOR).map { |link| link['href'] }
                         .find { |href| href.include?('/download/file/') }

      if embedded_url.blank?
        logger.error "No embedded file download link found in #{url}"
        return false
      end

      # Convert relative links to absolute if necessary
      embedded_url = URI.join(url, embedded_url).to_s unless embedded_url.start_with?('http')
      logger.info "Found embedded file download link: #{embedded_url}"

      download_resource(embedded_url, download_path, logger)
      return true
    rescue => e
      logger.error "Error extracting embedded file from #{url}: #{e.message}"
      return false
    end
  end

  # Download the resource from the provided URL
  def download_resource(url, download_path, logger)
    begin
      # Open the URL and read the content as binary data
      data = URI.open(url).read
  
      # Write the binary data to the file
      File.open(download_path, 'wb') do |file|
        file.write(data)
      end
  
      logger.info "Downloaded resource from #{url} to #{download_path}"
      return true
    rescue => e
      logger.error "Error downloading resource #{url}: #{e.message}"
      return false
    end
  end

  # Handle the downloaded file based on its mime type
  def handle_downloaded_file(record, download_path, logger)
    mime_type = `file --brief --mime-type #{Shellwords.escape(download_path)}`.strip
    if mime_type.include?('pdf')
      GeneratePdfThumbsJob.perform_later(record.id, download_path)
    elsif mime_type.include?('image')
      GenerateImageThumbsJob.perform_later(record.id, download_path)
    end
  end

  # Check if the URL points directly to a supported file type
  def direct_file?(url)
    return false if url.nil?  # Ensure we handle nil gracefully

    # if path ends with /download or /download/ or /download? or /download/? then it's a direct file link
    return true if url.match?(/\/download\/?(\?|$)/)

    FILE_EXTENSIONS.any? { |ext| url.downcase.end_with?(ext) }
  end

  def handle_dlg_record(url, download_path, logger)
    logger.info "Processing DLG record: #{url}"
    record = Acda.where(id: id).first
    
    html = URI.open(url).read
    doc = Nokogiri::HTML(html)
    
    # Check for PDF first
    pdf_url = doc.css('a[href*="/download/pdf/"]').attr('href')&.value ||
              doc.css('a[href$=".pdf"]').attr('href')&.value
              
    if pdf_url
      logger.info "Found PDF URL: #{pdf_url}"
      pdf_url = URI.join(url, pdf_url).to_s unless pdf_url.start_with?('http')
      download_resource(pdf_url, download_path, logger)
      record.dc_type = "Text"
      record.save!
      return
    end
    
    # If no PDF, look for image
    image_url = doc.css('img.image-large').attr('src')&.value ||
                doc.css('meta[property="og:image"]').attr('content')&.value ||
                doc.css('a[href*="/download/image/"]').attr('href')&.value
    
    if image_url
      logger.info "Found DLG image URL: #{image_url}"
      image_url = URI.join(url, image_url).to_s unless image_url.start_with?('http')
      download_resource(image_url, download_path, logger)
      record.dc_type = "Image"
      record.save!
    else
      # Try IIIF URL construction as last resort
      id = url.split('/').last
      iiif_url = "https://dlg.usg.edu/images/iiif/2/#{id}/full/800,/0/default.jpg"
      logger.info "Attempting IIIF URL: #{iiif_url}"
      download_resource(iiif_url, download_path, logger)
      record.dc_type = "Image"
      record.save!
    end
  rescue StandardError => e
    logger.error "Failed to process DLG record #{url}: #{e.message}"
  end

  # Expanded handle_video_thumbnail method to support YouTube
  def handle_video_thumbnail(record, logger)
    # Try to determine if it's a video link
    url = record.available_by.presence || record.available_at.presence
    return false unless url
    
    download_path = "#{Rails.root}/tmp/downloads/#{record.id}"
    FileUtils.mkdir_p(File.dirname(download_path)) unless File.exist?(File.dirname(download_path))
    
    # Handle Vimeo videos
    if url.include?('vimeo.com')
      logger.info "Processing Vimeo video: #{url}"
      
      # Extract Vimeo ID from URL
      vimeo_id = extract_vimeo_id(url)
      return false unless vimeo_id
      
      # Construct the oEmbed API URL
      oembed_url = "https://vimeo.com/api/oembed.json?url=https://vimeo.com/#{vimeo_id}"
      
      begin
        # Fetch video metadata
        response = URI.open(oembed_url).read
        metadata = JSON.parse(response)
        
        # Get the thumbnail URL
        thumbnail_url = metadata['thumbnail_url']
        
        if thumbnail_url
          logger.info "Found Vimeo thumbnail: #{thumbnail_url}"
          
          # Download the thumbnail
          success = download_resource(thumbnail_url, download_path, logger)
          
          if success
            # Process the downloaded thumbnail
            GenerateImageThumbsJob.perform_later(record.id, download_path)
            return true
          end
        end
      rescue => e
        logger.error "Error processing Vimeo thumbnail: #{e.message}"
        return false
      end
    
    # Handle YouTube videos
    elsif url.include?('youtube.com') || url.include?('youtu.be')
      logger.info "Processing YouTube video: #{url}"
      
      # Extract YouTube ID from URL
      youtube_id = extract_youtube_id(url)
      return false unless youtube_id
      
      # YouTube provides multiple thumbnail options:
      # - maxresdefault.jpg (HD thumbnail)
      # - hqdefault.jpg (high quality)
      # - mqdefault.jpg (medium quality)
      # - default.jpg (standard quality)
      
      # Try the HD thumbnail first, then fall back to lower quality
      thumbnail_urls = [
        "https://img.youtube.com/vi/#{youtube_id}/maxresdefault.jpg",
        "https://img.youtube.com/vi/#{youtube_id}/hqdefault.jpg",
        "https://img.youtube.com/vi/#{youtube_id}/mqdefault.jpg",
        "https://img.youtube.com/vi/#{youtube_id}/default.jpg"
      ]
      
      # Try each thumbnail URL until one works
      thumbnail_urls.each do |thumbnail_url|
        logger.info "Trying YouTube thumbnail: #{thumbnail_url}"
        success = download_resource(thumbnail_url, download_path, logger)
        
        if success && File.size(download_path) > 1000 # Ensure it's not an error image
          logger.info "Successfully downloaded YouTube thumbnail: #{thumbnail_url}"
          GenerateImageThumbsJob.perform_later(record.id, download_path)
          return true
        end
      end
      
      logger.error "Failed to download any YouTube thumbnails for #{youtube_id}"
      return false
    end
    
    # If we get here, we couldn't handle the video
    logger.info "Unable to extract thumbnail from video URL: #{url}"
    return false
  end

  # Helper method to extract Vimeo ID from various URL formats
  def extract_vimeo_id(url)
    # Match patterns like vimeo.com/123456789 or player.vimeo.com/video/123456789
    if url =~ /vimeo\.com\/(\d+)/ || url =~ /player\.vimeo\.com\/video\/(\d+)/
      return $1
    end
    nil
  end

  # Helper method to extract YouTube ID from various URL formats
  def extract_youtube_id(url)
    # Match patterns like:
    # - youtube.com/watch?v=VIDEO_ID
    # - youtu.be/VIDEO_ID
    # - youtube.com/embed/VIDEO_ID
    # - youtube.com/v/VIDEO_ID
    if url =~ /youtube\.com\/watch\?v=([^&]+)/ ||
       url =~ /youtu\.be\/([^?]+)/ ||
       url =~ /youtube\.com\/embed\/([^?]+)/ ||
       url =~ /youtube\.com\/v\/([^?]+)/
      return $1
    end
    nil
  end

  def create_default_video_thumbnail(record, download_path, logger)
    # Create a simple video thumbnail with the record title
    begin
      MiniMagick::Image.new(400, 300, "white") do |image|
        # Add video play icon and title
        image.combine_options do |c|
          c.gravity "center"
          c.pointsize "48"
          c.draw "text 0,0 '▶'"
          c.pointsize "18"
          c.draw "text 0,50 'Video'"
        end
        image.write(download_path)
      end
      
      logger.info "Created default video thumbnail"
      GenerateImageThumbsJob.perform_later(record.id, download_path)
      return true
    rescue => e
      logger.error "Failed to create default thumbnail: #{e.message}"
      
      # Even if we fail, mark the job as completed to prevent infinite retries
      record.queued_job = 'completed'
      record.save_with_retry!(validate: false)
      return false
    end
  end
end

