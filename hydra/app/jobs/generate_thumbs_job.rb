class GenerateThumbsJob < ApplicationJob
  queue_as :import

  FILE_EXTENSIONS = %w[.jpg .jpeg .png .gif .pdf].freeze

  def perform(id)
    record = Acda.where(id: id).first
    return unless record # Guard against deleted records
    
    # Early returns for unsupported types
    return if record.dc_type.nil?
    return if ['Sound', 'Moving'].include?(record.dc_type)

    # Set up logging
    log_directory = "#{Rails.root}/log/generate_thumbs"
    FileUtils.mkdir_p(log_directory) unless File.exist?(log_directory)
    logger = Logger.new("#{log_directory}/thumbnail_#{id}.log")

    download_path = "#{Rails.root}/tmp/downloads/#{id}"
    FileUtils.mkdir_p(File.dirname(download_path)) unless File.exist?(File.dirname(download_path))

    # Clear URL selection logic
    if record.available_by.present?
      logger.info "Using available_by for download: #{record.available_by}"
      process_url(record.available_by, download_path, logger)
    elsif record.available_at.present?
      logger.info "Using available_at for external resource: #{record.available_at}"
      process_url(record.available_at, download_path, logger)
    end

    handle_downloaded_file(record, download_path, logger)
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
      return
    end

    # Convert relative links to absolute if necessary
    embedded_url = URI.join(url, embedded_url).to_s unless embedded_url.start_with?('http')
    logger.info "Found embedded file download link: #{embedded_url}"

    download_resource(embedded_url, download_path, logger)
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
    rescue => e
      logger.error "Error downloading resource #{url}: #{e.message}"
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
end

