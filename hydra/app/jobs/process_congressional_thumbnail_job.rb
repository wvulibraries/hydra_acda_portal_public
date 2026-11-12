# ActiveStorage/CongressionalRecord equivalent of ProcessThumbnailJob.
# Deliberately a SEPARATE job, not a modification of ProcessThumbnailJob -
# the Acda/Fedora pipeline keeps running untouched. Starts with the
# dominant case (preview URL present) plus the placeholder fallback;
# video/PDF paths and the (separately-triggered, admin-only)
# queue_pending_thumbnails chain come in a later pass.
#
# Key difference from the Fedora version: ActiveStorage's #attach persists
# immediately - no trailing record.save! needed for the files themselves
# (with_thumbnail_lock still saves the record for the queued_job state).
class ProcessCongressionalThumbnailJob < ApplicationJob
  queue_as :import

  def self.perform_once(id, *args)
    return if already_queued?(id)
    perform_later(id, *args)
  end

  
  def perform(id)
    CongressionalRecord.with_thumbnail_lock(id) do |record|
      log_directory = "#{Rails.root}/log/thumbnails"
      FileUtils.mkdir_p(log_directory) unless File.exist?(log_directory)
      logger = Logger.new("#{log_directory}/#{id}.log")
      logger.info "Starting thumbnail processing for #{id} (CongressionalRecord)"

      if record.dc_type == 'MovingImage' || record.dc_type == 'Moving'
        process_video_thumbnail(record, logger)
      elsif record.preview.present?
        process_preview_thumbnail(record, logger)
      elsif record.dc_type == 'Image'
        process_image_thumbnail(record, logger)
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

    if record.available_by&.include?('vimeo') || record.available_at&.include?('vimeo')
      url = record.available_by || record.available_at
      vimeo_id = extract_vimeo_id(url)

      if vimeo_id
        logger.info "Found Vimeo ID: #{vimeo_id}"
        download_path = "#{Rails.root}/tmp/downloads/#{record.id}_vimeo_ar.jpg"

        if download_vimeo_high_quality(vimeo_id, download_path, logger)
          logger.info "Successfully downloaded high-quality Vimeo image"
          attach_images_to_record(record, download_path, logger)
          return
        elsif download_vimeo_thumbnail(vimeo_id, download_path, logger)
          logger.info "Successfully downloaded Vimeo thumbnail"
          attach_thumbnail_to_record(record, download_path, logger)
          return
        end
      end
    elsif record.available_by&.include?('youtube') || record.available_at&.include?('youtube')
      url = record.available_by || record.available_at
      youtube_id = extract_youtube_id(url)

      if youtube_id
        logger.info "Found YouTube ID: #{youtube_id}"

        download_path = "#{Rails.root}/tmp/downloads/#{record.id}_youtube_hq_ar.jpg"
        youtube_hq_url = "https://img.youtube.com/vi/#{youtube_id}/maxresdefault.jpg"

        if download_file(youtube_hq_url, download_path, logger)
          logger.info "Successfully downloaded high-quality YouTube image"
          attach_images_to_record(record, download_path, logger)
          return
        else
          download_path = "#{Rails.root}/tmp/downloads/#{record.id}_youtube_ar.jpg"
          youtube_thumbnail_url = "https://img.youtube.com/vi/#{youtube_id}/hqdefault.jpg"

          if download_file(youtube_thumbnail_url, download_path, logger)
            logger.info "Successfully downloaded YouTube thumbnail"
            attach_thumbnail_to_record(record, download_path, logger)
            return
          end
        end
      end
    end

    if record.preview.present?
      logger.info "Using preview URL as fallback for video thumbnail"
      process_preview_thumbnail(record, logger)
      return
    end

    logger.info "Creating default video thumbnail"
    create_default_video_thumbnail(record, logger)
  end

  def process_image_thumbnail(record, logger)
    logger.info "Processing image thumbnail for #{record.id} using available_by: #{record.available_by}"
    download_path = "#{Rails.root}/tmp/downloads/#{record.id}_image_ar.jpg"

    if download_file(record.available_by, download_path, logger)
      logger.info "Successfully downloaded image"
      attach_images_to_record(record, download_path, logger)
    else
      logger.error "Failed to download image"
      create_placeholder_thumbnail(record, logger)
    end
  end

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
      download_path = "#{Rails.root}/tmp/downloads/#{record.id}_pdf_ar.pdf"
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

  def create_default_video_thumbnail(record, logger)
    logger.info "Creating default video thumbnail for #{record.id}"
    download_path = "#{Rails.root}/tmp/downloads/#{record.id}_video_ar.jpg"

    begin
      text = "Video: #{record.title.presence || 'No Title'}"
      create_video_placeholder(text, download_path)
      attach_thumbnail_to_record(record, download_path, logger)
      logger.info "Created default video thumbnail"
    rescue => e
      logger.error "Failed to create video thumbnail: #{e.message}"
    end
  end

  def extract_vimeo_id(url)
    return nil unless url.present?

    if url =~ /vimeo\.com\/(\d+)/
      $1
    elsif url =~ /player\.vimeo\.com\/video\/(\d+)/
      $1
    end
  end

  def extract_youtube_id(url)
    return nil unless url.present?

    if url =~ /youtube\.com\/watch\?v=([^&]+)/ ||
       url =~ /youtu\.be\/([^?]+)/ ||
       url =~ /youtube\.com\/embed\/([^?]+)/ ||
       url =~ /youtube\.com\/v\/([^?]+)/
      $1
    end
  end

  def download_vimeo_thumbnail(vimeo_id, output_path, logger)
    oembed_url = "https://vimeo.com/api/oembed.json?url=https://vimeo.com/#{vimeo_id}"
    response = Net::HTTP.get_response(URI.parse(oembed_url))

    if response.is_a?(Net::HTTPSuccess)
      thumbnail_url = JSON.parse(response.body)['thumbnail_url']
      return download_file(thumbnail_url, output_path, logger) if thumbnail_url.present?
    end
    false
  rescue => e
    logger.error "Error getting Vimeo thumbnail: #{e.message}"
    false
  end

  def download_vimeo_high_quality(vimeo_id, output_path, logger)
    api_url = "https://vimeo.com/api/v2/video/#{vimeo_id}.json"
    response = Net::HTTP.get_response(URI.parse(api_url))

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      if data.is_a?(Array) && data.first
        thumbnail_url = data.first['thumbnail_large']
        return download_file(thumbnail_url, output_path, logger) if thumbnail_url.present?
      end
    end
    false
  rescue => e
    logger.error "Error getting high-quality Vimeo image: #{e.message}"
    false
  end

  def verify_pdf(file_path, logger)
    return false unless File.exist?(file_path) && File.size(file_path) > 1000

    File.open(file_path, 'rb') do |file|
      header = file.read(5)
      if header == "%PDF-"
        logger.info "File verified as PDF"
        return true
      else
        file.rewind
        content_sample = file.read(1000)
        if content_sample.include?('<html') || content_sample.include?('<HTML')
          logger.error "Downloaded file appears to be HTML, not a PDF"
          return false
        end
        logger.error "File does not have PDF header (got: #{header.inspect})"
        false
      end
    end
  rescue => e
    logger.error "Error verifying PDF: #{e.message}"
    false
  end

  def valid_image?(file_path, logger)
    image = MiniMagick::Image.open(file_path)
    width = image.width
    height = image.height
    logger.info "Generated image dimensions: #{width}x#{height}"
    width > 0 && height > 0
  rescue => e
    logger.error "Error validating image: #{e.message}"
    false
  end

  def generate_thumbnail_from_pdf(record, pdf_path, logger)
    output_path = "#{pdf_path}_page1.jpg"
    command = "convert -density 150 -quality 90 -resize 1200x1200\\> -flatten \"#{pdf_path}[0]\" \"#{output_path}\""
    logger.info "Running PDF conversion command: #{command}"

    output = `#{command} 2>&1`
    result = $?.success?
    logger.info "PDF conversion result: #{result ? 'Success' : 'Failed'}"
    logger.info "Command output: #{output}" if output.present?

    if File.exist?(output_path)
      if valid_image?(output_path, logger)
        logger.info "Successfully generated valid image from PDF"
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
    FileUtils.rm_f(pdf_path) if pdf_path && File.exist?(pdf_path)
  end

  def create_video_placeholder(text, output_path)
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

  def process_preview_thumbnail(record, logger)
    logger.info "Processing preview thumbnail for #{record.id} using URL: #{record.preview}"
    download_path = "#{Rails.root}/tmp/downloads/#{record.id}_preview_ar.jpg"

    if download_file(record.preview, download_path, logger)
      logger.info "Successfully downloaded preview image"
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

  def create_placeholder_thumbnail(record, logger)
    logger.info "Creating placeholder thumbnail for #{record.id}"
    download_path = "#{Rails.root}/tmp/downloads/#{record.id}_placeholder_ar.jpg"

    begin
      text = record.title.presence || "No Preview Available"
      create_text_image(text, download_path)
      attach_thumbnail_to_record(record, download_path, logger)
      logger.info "Created placeholder thumbnail"
    rescue => e
      logger.error "Failed to create placeholder: #{e.message}"
    end
  end

  # --- Ported verbatim from ProcessThumbnailJob - model-agnostic, downloads
  # bytes to local disk, no Fedora calls at all ---

  def download_file(url, output_path, logger)
    return false if url.blank?

    FileUtils.mkdir_p(File.dirname(output_path)) unless File.exist?(File.dirname(output_path))

    begin
      current_url = url
      max_redirects = 5
      redirect_count = 0

      while redirect_count < max_redirects
        logger.info "Attempting to download from URL: #{current_url} (redirect ##{redirect_count})"
        uri = URI.parse(current_url)

        request = Net::HTTP::Get.new(uri)
        request['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        request['Accept'] = '*/*'
        request['Cookie'] = 'dspace.cookie.login=true' if current_url.include?('evols.library.manoa.hawaii.edu')

        response = Net::HTTP.start(uri.hostname, uri.port,
                                 use_ssl: uri.scheme == 'https',
                                 verify_mode: OpenSSL::SSL::VERIFY_NONE,
                                 open_timeout: 30,
                                 read_timeout: 30) do |http|
          http.request(request)
        end

        case response
        when Net::HTTPSuccess
          File.open(output_path, 'wb') { |file| file.write(response.body) }
          logger.info "Successfully downloaded file to #{output_path} (#{File.size(output_path)} bytes)"
          return true
        when Net::HTTPRedirection
          location = response['location']
          location = "#{uri.scheme}://#{uri.host}#{location}" if location.start_with?('/')
          logger.info "Following redirect to: #{location}"
          current_url = location
          redirect_count += 1
        else
          logger.error "Failed to download file, status: #{response.code} #{response.message}"
          return false
        end
      end

      logger.error "Exceeded maximum number of redirects (#{max_redirects})"
      false
    rescue => e
      logger.error "Error downloading file: #{e.message}\n#{e.backtrace.join("\n")}"
      false
    end
  end

  def check_image_quality(file_path, logger)
    begin
      image = MiniMagick::Image.open(file_path)
      width = image.width
      height = image.height
      logger.info "Image dimensions: #{width}x#{height}"
      width >= 600 || height >= 600
    rescue => e
      logger.error "Error checking image quality: #{e.message}"
      false
    end
  end

  def generate_thumbnail(input_path, max_dimension, logger)
    output_path = "#{input_path}_thumb.jpg"
    begin
      image = MiniMagick::Image.open(input_path)
      image.resize "#{max_dimension}x#{max_dimension}>"
      image.format "jpg"
      image.write output_path
      output_path
    rescue => e
      logger.error "Error generating thumbnail: #{e.message}"
      nil
    end
  end

  def create_text_image(text, output_path)
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

  # --- Adapted for ActiveStorage instead of AcdaFile/Fedora ---

  def attach_thumbnail_to_record(record, file_path, logger)
    thumb_path = generate_thumbnail(file_path, 250, logger)

    if thumb_path && File.exist?(thumb_path)
      record.thumbnail_file.attach(
        io: File.open(thumb_path),
        filename: "#{record.id}_thumbnail.jpg",
        content_type: 'image/jpeg'
      )
      logger.info "Successfully attached thumbnail to record"
      return true
    end
    false
  rescue => e
    logger.error "Error attaching thumbnail: #{e.message}"
    false
  ensure
    FileUtils.rm_f(file_path) if file_path && File.exist?(file_path)
    FileUtils.rm_f(thumb_path) if defined?(thumb_path) && thumb_path && File.exist?(thumb_path)
  end

  def attach_images_to_record(record, file_path, logger)
    thumb_path = generate_thumbnail(file_path, 250, logger)
    image_saved = false

    if File.exist?(file_path)
      record.image_file.attach(
        io: File.open(file_path),
        filename: "#{record.id}_image.jpg",
        content_type: 'image/jpeg'
      )
      image_saved = true
      logger.info "Attached full-size image to record"
    end

    if thumb_path && File.exist?(thumb_path)
      record.thumbnail_file.attach(
        io: File.open(thumb_path),
        filename: "#{record.id}_thumbnail.jpg",
        content_type: 'image/jpeg'
      )
      logger.info "Attached thumbnail to record"
    end

    image_saved
  rescue => e
    logger.error "Error attaching images: #{e.message}"
    false
  ensure
    FileUtils.rm_f(file_path) if file_path && File.exist?(file_path)
    FileUtils.rm_f(thumb_path) if defined?(thumb_path) && thumb_path && File.exist?(thumb_path)
  end
end