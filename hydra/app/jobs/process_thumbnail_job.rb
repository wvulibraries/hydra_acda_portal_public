class ProcessThumbnailJob < ApplicationJob
  queue_as :import
  
  def self.perform_once(id, *args)
    return if already_queued?(id)
    perform_later(id, *args)
  end
  
  def perform(id)
    Acda.with_thumbnail_lock(id) do |record|
      # Set up logging
      log_directory = "#{Rails.root}/log/thumbnails"
      FileUtils.mkdir_p(log_directory) unless File.exist?(log_directory)
      logger = Logger.new("#{log_directory}/#{id}.log")
      logger.info "Starting thumbnail processing for #{id}"

      # Determine the best approach based on content type
      if record.dc_type == 'MovingImage' || record.dc_type == 'Moving'
        process_video_thumbnail(record, logger)
      elsif record.preview.present?
        process_preview_thumbnail(record, logger)
      elsif record.dc_type == 'Image'
        process_image_thumbnail(record, logger)
      # Improved PDF detection - check for .pdf, /download, or /content in URL
      elsif record.available_by&.downcase&.end_with?('.pdf') ||
            record.available_by&.downcase&.include?('/download') ||
            record.available_by&.downcase&.include?('/content') ||
            (record.available_at&.downcase&.include?('/bitstreams/') && 
              (record.available_at&.downcase&.include?('/download') || record.available_at&.downcase&.include?('/content')))
        logger.info "Detected PDF-like URL pattern: #{record.available_by || record.available_at}"
        process_pdf_thumbnail(record, logger)
      else
        logger.info "No suitable thumbnail source found"
        create_placeholder_thumbnail(record, logger)
      end

      logger.info "Thumbnail processing completed for #{id}"
    end
  end
  
  private
  
  def process_video_thumbnail(record, logger)
    logger.info "Processing video thumbnail for #{record.id}"
    
    # Try to extract thumbnail from video URL
    if record.available_by&.include?('vimeo') || record.available_at&.include?('vimeo')
      url = record.available_by || record.available_at
      vimeo_id = extract_vimeo_id(url)
      
      if vimeo_id
        logger.info "Found Vimeo ID: #{vimeo_id}"
        # Try to get high-quality image first
        download_path = "#{Rails.root}/tmp/downloads/#{record.id}_vimeo.jpg"
        
        # Try to get the highest quality thumbnail available
        success = download_vimeo_high_quality(vimeo_id, download_path, logger)
        
        if success
          logger.info "Successfully downloaded high-quality Vimeo image"
          # Save both full image and thumbnail
          attach_images_to_record(record, download_path, logger)
          return
        else
          # Fall back to standard thumbnail
          success = download_vimeo_thumbnail(vimeo_id, download_path, logger)
          if success
            logger.info "Successfully downloaded Vimeo thumbnail"
            attach_thumbnail_to_record(record, download_path, logger)
            return
          end
        end
      end
    elsif record.available_by&.include?('youtube') || record.available_at&.include?('youtube')
      url = record.available_by || record.available_at
      youtube_id = extract_youtube_id(url)
      
      if youtube_id
        logger.info "Found YouTube ID: #{youtube_id}"
        
        # Try to get maxresdefault (highest quality) first
        download_path = "#{Rails.root}/tmp/downloads/#{record.id}_youtube_hq.jpg"
        youtube_hq_url = "https://img.youtube.com/vi/#{youtube_id}/maxresdefault.jpg"
        hq_success = download_file(youtube_hq_url, download_path, logger)
        
        if hq_success
          logger.info "Successfully downloaded high-quality YouTube image"
          # Save both full image and thumbnail
          attach_images_to_record(record, download_path, logger)
          return
        else
          # Fall back to standard thumbnail
          download_path = "#{Rails.root}/tmp/downloads/#{record.id}_youtube.jpg"
          youtube_thumbnail_url = "https://img.youtube.com/vi/#{youtube_id}/hqdefault.jpg"
          success = download_file(youtube_thumbnail_url, download_path, logger)
          
          if success
            logger.info "Successfully downloaded YouTube thumbnail"
            attach_thumbnail_to_record(record, download_path, logger)
            return
          end
        end
      end
    end
    
    # If we have a preview URL, try that
    if record.preview.present?
      logger.info "Using preview URL as fallback for video thumbnail"
      process_preview_thumbnail(record, logger)
      return
    end
    
    # Final fallback - create a default video thumbnail
    logger.info "Creating default video thumbnail"
    create_default_video_thumbnail(record, logger)
  end
  
  def process_preview_thumbnail(record, logger)
    logger.info "Processing preview thumbnail for #{record.id} using URL: #{record.preview}"
    download_path = "#{Rails.root}/tmp/downloads/#{record.id}_preview.jpg"
    
    if download_file(record.preview, download_path, logger)
      logger.info "Successfully downloaded preview image"
      
      # Check if this is a high-quality image or just a thumbnail
      is_high_quality = check_image_quality(download_path, logger)
      
      if is_high_quality
        logger.info "Preview appears to be high quality, saving as both full image and thumbnail"
        attach_images_to_record(record, download_path, logger)
      else
        logger.info "Preview appears to be a small thumbnail, saving as thumbnail only"
        attach_thumbnail_to_record(record, download_path, logger)
      end
    else
      logger.error "Failed to download preview image"
      create_placeholder_thumbnail(record, logger)
    end
  end
  
  def process_image_thumbnail(record, logger)
    logger.info "Processing image thumbnail for #{record.id} using available_by: #{record.available_by}"
    download_path = "#{Rails.root}/tmp/downloads/#{record.id}_image.jpg"
    
    if download_file(record.available_by, download_path, logger)
      logger.info "Successfully downloaded image"
      attach_images_to_record(record, download_path, logger)
    else
      logger.error "Failed to download image"
      create_placeholder_thumbnail(record, logger)
    end
  end
  
  # Update the process_pdf_thumbnail method to handle both URL patterns
  def process_pdf_thumbnail(record, logger)
    url_to_use = nil

    if record.available_by&.downcase&.end_with?('.pdf') ||
       record.available_by&.downcase&.include?('/download') ||
       record.available_by&.downcase&.include?('/content')
      url_to_use = record.available_by
      logger.info "Using available_by for PDF download: #{url_to_use}"
    elsif record.available_at&.downcase&.include?('/bitstreams/') &&
          (record.available_at&.downcase&.include?('/download') || record.available_at&.downcase&.include?('/content'))
      url_to_use = record.available_at
      logger.info "Using available_at for PDF download: #{url_to_use}"
    end

    if url_to_use.present?
      download_path = "#{Rails.root}/tmp/downloads/#{record.id}_pdf.pdf"
      if download_file(url_to_use, download_path, logger)
        if verify_pdf(download_path, logger)
          logger.info "Successfully downloaded PDF"
          generate_thumbnail_from_pdf(record, download_path, logger)
        else
          logger.error "Downloaded file is not a valid PDF"
          create_placeholder_thumbnail(record, logger)
        end
      else
        logger.error "Failed to download PDF"
        create_placeholder_thumbnail(record, logger)
      end
    else
      logger.error "No suitable PDF URL found"
      create_placeholder_thumbnail(record, logger)
    end
  end
  
  def create_placeholder_thumbnail(record, logger)
    logger.info "Creating placeholder thumbnail for #{record.id}"
    download_path = "#{Rails.root}/tmp/downloads/#{record.id}_placeholder.jpg"
    
    begin
      # Create a simple placeholder with the record title
      text = record.title.presence || "No Preview Available"
      create_text_image(text, download_path)
      attach_thumbnail_to_record(record, download_path, logger)
      logger.info "Created placeholder thumbnail"
    rescue => e
      logger.error "Failed to create placeholder: #{e.message}"
    end
  end
  
  def create_default_video_thumbnail(record, logger)
    logger.info "Creating default video thumbnail for #{record.id}"
    download_path = "#{Rails.root}/tmp/downloads/#{record.id}_video.jpg"
    
    begin
      # Create a simple video thumbnail with play button
      text = "Video: #{record.title.presence || 'No Title'}"
      create_video_placeholder(text, download_path)
      attach_thumbnail_to_record(record, download_path, logger)
      logger.info "Created default video thumbnail"
    rescue => e
      logger.error "Failed to create video thumbnail: #{e.message}"
    end
  end
  
  # Helper methods
  
  def download_file(url, output_path, logger)
    return false if url.blank?
    
    FileUtils.mkdir_p(File.dirname(output_path)) unless File.exist?(File.dirname(output_path))
    
    begin
      # Configure to follow redirects
      uri = URI.parse(url)
      
      # Start with the initial URL
      current_url = url
      max_redirects = 5
      redirect_count = 0
      
      while redirect_count < max_redirects
        logger.info "Attempting to download from URL: #{current_url} (redirect ##{redirect_count})"
        uri = URI.parse(current_url)
        
        # Configure request with proper headers
        request = Net::HTTP::Get.new(uri)
        request['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        request['Accept'] = '*/*'
        
        # Add cookie handling for DSpace repositories
        request['Cookie'] = 'dspace.cookie.login=true' if current_url.include?('evols.library.manoa.hawaii.edu')
        
        # Make the actual HTTP request
        response = Net::HTTP.start(uri.hostname, uri.port, 
                                 use_ssl: uri.scheme == 'https',
                                 verify_mode: OpenSSL::SSL::VERIFY_NONE,
                                 open_timeout: 30,
                                 read_timeout: 30) do |http|
          http.request(request)
        end
        
        # Handle different response types
        case response
        when Net::HTTPSuccess
          # Success! Write the file
          File.open(output_path, 'wb') do |file|
            file.write(response.body)
          end
          logger.info "Successfully downloaded file to #{output_path} (#{File.size(output_path)} bytes)"
          return true
          
        when Net::HTTPRedirection
          # Follow the redirect
          location = response['location']
          
          # Some servers return relative URLs
          if location.start_with?('/')
            location = "#{uri.scheme}://#{uri.host}#{location}"
          end
          
          logger.info "Following redirect to: #{location}"
          current_url = location
          redirect_count += 1
          
        else
          # Something else went wrong
          logger.error "Failed to download file, status: #{response.code} #{response.message}"
          return false
        end
      end
      
      # If we get here, we've exceeded max redirects
      logger.error "Exceeded maximum number of redirects (#{max_redirects})"
      return false
      
    rescue => e
      logger.error "Error downloading file: #{e.message}\n#{e.backtrace.join("\n")}"
      return false
    end
  end
  
  def extract_vimeo_id(url)
    return nil unless url.present?
    
    if url =~ /vimeo\.com\/(\d+)/
      return $1
    elsif url =~ /player\.vimeo\.com\/video\/(\d+)/
      return $1
    end
    nil
  end
  
  def extract_youtube_id(url)
    return nil unless url.present?
    
    if url =~ /youtube\.com\/watch\?v=([^&]+)/ ||
       url =~ /youtu\.be\/([^?]+)/ ||
       url =~ /youtube\.com\/embed\/([^?]+)/ ||
       url =~ /youtube\.com\/v\/([^?]+)/
      return $1
    end
    nil
  end
  
  def download_vimeo_thumbnail(vimeo_id, output_path, logger)
    begin
      # Use Vimeo oEmbed API to get thumbnail URL
      oembed_url = "https://vimeo.com/api/oembed.json?url=https://vimeo.com/#{vimeo_id}"
      uri = URI.parse(oembed_url)
      response = Net::HTTP.get_response(uri)
      
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        thumbnail_url = data['thumbnail_url']
        
        if thumbnail_url.present?
          return download_file(thumbnail_url, output_path, logger)
        end
      end
      return false
    rescue => e
      logger.error "Error getting Vimeo thumbnail: #{e.message}"
      return false
    end
  end
  
  def download_vimeo_high_quality(vimeo_id, output_path, logger)
    begin
      # Try to get higher quality image from Vimeo API
      # This uses a different endpoint that might return larger images
      api_url = "https://vimeo.com/api/v2/video/#{vimeo_id}.json"
      uri = URI.parse(api_url)
      response = Net::HTTP.get_response(uri)
      
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        if data.is_a?(Array) && data.first
          # Try to get the largest thumbnail available
          thumbnail_url = data.first['thumbnail_large'] 
          
          if thumbnail_url.present?
            return download_file(thumbnail_url, output_path, logger)
          end
        end
      end
      return false
    rescue => e
      logger.error "Error getting high-quality Vimeo image: #{e.message}"
      return false
    end
  end
  
  def attach_thumbnail_to_record(record, file_path, logger)
    begin
      # Generate different sizes if needed
      thumb_path = generate_thumbnail(file_path, 250, logger)
      
      # Attach to record
      if thumb_path && File.exist?(thumb_path)
        record.thumbnail_file = AcdaFile.new.tap do |f|
          f.content = File.open(thumb_path)
          f.original_name = "#{record.id}_thumbnail.jpg"
          f.mime_type = 'image/jpeg'
        end
        
        record.save_with_retry!(validate: false)
        logger.info "Successfully attached thumbnail to record"
        return true
      end
    rescue => e
      logger.error "Error attaching thumbnail: #{e.message}"
    ensure
      # Clean up temporary files
      FileUtils.rm_f(file_path) if file_path && File.exist?(file_path)
      FileUtils.rm_f(thumb_path) if defined?(thumb_path) && thumb_path && File.exist?(thumb_path)
    end
    false
  end
  
  def attach_images_to_record(record, file_path, logger)
    begin
      # Generate thumbnail first
      thumb_path = generate_thumbnail(file_path, 250, logger)
      
      # Also save the full-size image
      image_saved = false
      
      if File.exist?(file_path)
        # Attach the original image as the full-size image
        record.image_file = AcdaFile.new.tap do |f|
          f.content = File.open(file_path)
          f.original_name = "#{record.id}_image.jpg"
          f.mime_type = 'image/jpeg'
        end
        
        image_saved = true
        logger.info "Attached full-size image to record"
      end
      
      # Attach thumbnail
      if thumb_path && File.exist?(thumb_path)
        record.thumbnail_file = AcdaFile.new.tap do |f|
          f.content = File.open(thumb_path)
          f.original_name = "#{record.id}_thumbnail.jpg"
          f.mime_type = 'image/jpeg'
        end
        
        logger.info "Attached thumbnail to record"
      end
      
      # Save the record with both images
      record.save_with_retry!(validate: false)
      
      return image_saved
    rescue => e
      logger.error "Error attaching images: #{e.message}"
    ensure
      # Clean up temporary files
      FileUtils.rm_f(file_path) if file_path && File.exist?(file_path)
      FileUtils.rm_f(thumb_path) if defined?(thumb_path) && thumb_path && File.exist?(thumb_path)
    end
    false
  end
  
  def generate_thumbnail(input_path, max_dimension, logger)
    output_path = "#{input_path}_thumb.jpg"
    
    begin
      image = MiniMagick::Image.open(input_path)
      image.resize "#{max_dimension}x#{max_dimension}>"
      image.format "jpg"
      image.write output_path
      return output_path
    rescue => e
      logger.error "Error generating thumbnail: #{e.message}"
      return nil
    end
  end
  
  def generate_thumbnail_from_pdf(record, pdf_path, logger)
    begin
      # Use PDF first page as thumbnail
      output_path = "#{pdf_path}_page1.jpg"
      
      # Use imagemagick to convert first page of PDF to image at higher quality
      # Added -flatten to handle transparency, limited size to prevent huge files
      command = "convert -density 150 -quality 90 -resize 1200x1200\\> -flatten \"#{pdf_path}[0]\" \"#{output_path}\""
      logger.info "Running PDF conversion command: #{command}"
      
      # Capture the command output for debugging
      output = `#{command} 2>&1`
      result = $?.success?
      
      logger.info "PDF conversion result: #{result ? 'Success' : 'Failed'}"
      logger.info "Command output: #{output}" if output.present?
      
      if File.exist?(output_path)
        # Check if the generated file is valid
        image_valid = valid_image?(output_path, logger)
        
        if image_valid
          logger.info "Successfully generated valid image from PDF"
          # Save both the full-size image and thumbnail
          attach_images_to_record(record, output_path, logger)
        else
          logger.error "Generated image from PDF is invalid"
          create_placeholder_thumbnail(record, logger)
        end
      else
        logger.error "Failed to convert PDF to image, output file not created"
        create_placeholder_thumbnail(record, logger)
      end
    rescue => e
      logger.error "Error generating PDF thumbnail: #{e.message}\n#{e.backtrace.join("\n")}"
      create_placeholder_thumbnail(record, logger)
    ensure
      # Clean up temporary files
      FileUtils.rm_f(pdf_path) if pdf_path && File.exist?(pdf_path)
    end
  end

  # Add this helper method to verify PDF files
  def verify_pdf(file_path, logger)
    begin
      # Check if file exists and has reasonable size
      return false unless File.exist?(file_path) && File.size(file_path) > 1000
      
      # Check if file starts with %PDF-
      File.open(file_path, 'rb') do |file|
        header = file.read(5)
        if header == "%PDF-"
          logger.info "File verified as PDF"
          return true
        else
          # Sometimes repositories send HTML error pages with 200 status
          # Try to detect this by looking for HTML tags
          file.rewind
          content_sample = file.read(1000)
          if content_sample.include?('<html') || content_sample.include?('<HTML')
            logger.error "Downloaded file appears to be HTML, not a PDF"
            return false
          end
          
          logger.error "File does not have PDF header (got: #{header.inspect})"
          return false
        end
      end
    rescue => e
      logger.error "Error verifying PDF: #{e.message}"
      return false
    end
  end

  # Helper methods
  
  def valid_image?(file_path, logger)
    begin
      # Try to open the image with MiniMagick to validate it
      image = MiniMagick::Image.open(file_path)
      width = image.width
      height = image.height
      
      # Log image details
      logger.info "Generated image dimensions: #{width}x#{height}"
      
      # Consider valid if it has positive dimensions
      return width > 0 && height > 0
    rescue => e
      logger.error "Error validating image: #{e.message}"
      return false
    end
  end
  
  def generate_thumbnail_from_image(record, image_path, logger)
    begin
      # Resize the image to create a thumbnail
      attach_images_to_record(record, image_path, logger)
    rescue => e
      logger.error "Error generating image thumbnail: #{e.message}"
      create_placeholder_thumbnail(record, logger)
    end
  end
  
  def create_text_image(text, output_path)
    # Create a simple image with text
    FileUtils.mkdir_p(File.dirname(output_path)) unless File.exist?(File.dirname(output_path))
    
    MiniMagick::Tool::Convert.new do |convert|
      convert << "-size" << "400x300"
      convert << "xc:white"
      convert << "-gravity" << "center"
      convert << "-pointsize" << "18"
      convert << "-annotate" << "+0+0" << text
      convert << output_path
    end
  end
  
  def create_video_placeholder(text, output_path)
    # Create a video placeholder with play button
    FileUtils.mkdir_p(File.dirname(output_path)) unless File.exist?(File.dirname(output_path))
    
    MiniMagick::Tool::Convert.new do |convert|
      convert << "-size" << "400x300"
      convert << "xc:black"
      convert << "-gravity" << "center"
      convert << "-fill" << "white"
      convert << "-pointsize" << "48"
      convert << "-annotate" << "+0-40" << "▶"
      convert << "-pointsize" << "18"
      convert << "-annotate" << "+0+40" << text
      convert << output_path
    end
  end
  
  def check_image_quality(file_path, logger)
    begin
      # Use MiniMagick to analyze the image
      image = MiniMagick::Image.open(file_path)
      width = image.width
      height = image.height
      
      # Log the dimensions
      logger.info "Image dimensions: #{width}x#{height}"
      
      # Determine if this is likely a high-quality image based on size
      # A typical thumbnail might be around 250px wide, while a full image
      # would be larger - using 600px as a reasonable threshold
      if width >= 600 || height >= 600
        logger.info "Image appears to be high quality (dimensions >= 600px)"
        return true
      else
        logger.info "Image appears to be a thumbnail (dimensions < 600px)"
        return false
      end
    rescue => e
      logger.error "Error checking image quality: #{e.message}"
      # Default to treating it as a thumbnail if we can't determine
      return false
    end
  end
end
