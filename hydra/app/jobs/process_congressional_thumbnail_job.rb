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

      if record.preview.present?
        process_preview_thumbnail(record, logger)
      else
        logger.info "No preview URL - creating placeholder thumbnail"
        create_placeholder_thumbnail(record, logger)
      end

      logger.info "Thumbnail processing completed for #{id}"
    end
  end

  private

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