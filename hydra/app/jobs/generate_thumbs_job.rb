class GenerateThumbsJob < ApplicationJob
  queue_as :import

  FILE_EXTENSIONS = %w[.jpg .jpeg .png .gif .pdf].freeze

  def perform(id)
    # Set logger to new log file for each record - useful for debugging
    log_directory = "#{Rails.root}/log/generate_thumbs"
    FileUtils.mkdir_p(log_directory) unless File.exist?(log_directory)

    logger = Logger.new("#{log_directory}/thumbnail_#{id}.log")

    # Log the start of the job
    logger.info "Starting thumbnail generation for Acda #{id}"

    # find record    
    record = Acda.where(id: id).first

    # Log if record not found
    if record.nil?
      logger.error "Record with id #{id} not found."
      return
    end

    return if record.dc_type.nil?
    return if ['Sound', 'Moving'].include?(record.dc_type)

    # Log dc_type
    logger.info "dc_type: #{record.dc_type}"

    # temp folder to store downloaded files
    file_path = "/home/hydra/tmp/download"

    # make folder if it doesn't exist
    FileUtils.mkdir_p(file_path) unless File.exist?(file_path)

    # add id to file path so we have full path and file name.
    download_path = "#{file_path}/#{id}"

    # Determine which URL to use: priority on `available_by`, fallback to `available_at`
    if record.available_by.present?
      logger.info "Using available_by for download: #{record.available_by}"
      process_url(record.available_by, download_path, logger)
    elsif record.available_at.present?
      logger.info "Using available_at for external resource: #{record.available_at}"
      process_url(record.available_at, download_path, logger)
    else
      logger.error "No available_by or available_at URL found for record #{id}."
      return
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
    else
      logger.info "Unsupported MIME type for record #{record.id}: #{mime_type}"
    end
  end

  # Check if the URL points directly to a supported file type
  def direct_file?(url)
    return false if url.nil?  # Ensure we handle nil gracefully
    FILE_EXTENSIONS.any? { |ext| url.downcase.end_with?(ext) }
  end
end

