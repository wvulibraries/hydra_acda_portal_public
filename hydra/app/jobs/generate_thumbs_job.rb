class GenerateThumbsJob < ApplicationJob
  queue_as :import

  FILE_EXTENSIONS = %w[.jpg .jpeg .png .gif .pdf].freeze

  def perform(id)
    record = Acda.where(id: id).first
    return unless record&.should_process_thumbnail?

    source_url = record.get_source_url
    return unless source_url

    download_path = setup_download_path(id)
    process_url(source_url, download_path, logger)
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
    
    # Log the processing chain
    Rails.logger.info "Processing chain for #{record.id}: DownloadAndSetThumbsJob -> GenerateThumbsJob -> #{mime_type.include?('pdf') ? 'GeneratePdfThumbsJob' : 'GenerateImageThumbsJob'}"
    
    job_class = case mime_type
                when /pdf/ then GeneratePdfThumbsJob
                when /image/ then GenerateImageThumbsJob
                end
    
    if job_class
      job_class.perform_later(record.id, download_path)
    else
      # Reset flag if we can't process this type
      record.queued_job = 'false'
      record.save!
    end
  end

  # Check if the URL points directly to a supported file type
  def direct_file?(url)
    return false if url.nil?  # Ensure we handle nil gracefully

    # if path ends with /download or /download/ or /download? or /download/? then it's a direct file link
    return true if url.match?(/\/download\/?(\?|$)/)

    FILE_EXTENSIONS.any? { |ext| url.downcase.end_with?(ext) }
  end
end

