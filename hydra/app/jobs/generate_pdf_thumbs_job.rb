class GeneratePdfThumbsJob < ApplicationJob
  include ImportLibrary

  queue_as :import
  
  retry_on Ldp::Gone, wait: :exponentially_longer, attempts: 3 do |job, error|
    Rails.logger.error "Resource gone for ID: #{job.arguments.first}, Error: #{error.message}"
  end

  def perform(id, download_path)
    # Initial validations
    return unless valid_for_processing?(id, download_path)

    begin
      # find record with error handling
      record = find_record(id)
      return unless record

      process_pdf(id, download_path, record)
    rescue StandardError => e
      Rails.logger.error "Failed to process PDF for ID: #{id}, Error: #{e.message}"
      raise e
    ensure
      cleanup_files(id, download_path)
    end
  end

  private

  def valid_for_processing?(id, download_path)
    return false unless id.present? && download_path.present?
    return false unless File.exist?(download_path)
    return false unless File.size(download_path) > 0
    
    true
  end

  def find_record(id)
    record = Acda.where(id: id).first
    Rails.logger.error "Record not found for ID: #{id}" unless record
    record
  end

  def process_pdf(id, download_path, record)
    pdf_dir = "/home/hydra/tmp/pdf"
    FileUtils.mkdir_p(pdf_dir)
    
    pdf_path = "#{pdf_dir}/#{id}.pdf"
    FileUtils.cp(download_path, pdf_path) # Use cp instead of mv to preserve original
    
    record.files.build unless record.files.present?
    
    process_images(id, pdf_path, record)
  end

  def process_images(id, pdf_path, record)
    image_path = setup_image_path(id)
    Rails.logger.info "Converting PDF to image for ID: #{id}"
    
    convert_pdf_to_image(pdf_path, image_path, id)
    final_image_path = find_image_path(id, image_path)
    
    if final_image_path
      Rails.logger.info "Image generated successfully at: #{final_image_path}"
      ImportLibrary.set_file(record.build_image_file, 'application/jpg', final_image_path)
      create_thumbnail(id, final_image_path, record)
    else
      Rails.logger.error "Failed to generate image for ID: #{id}"
      return false
    end
  end

  def setup_image_path(id)
    path = "/home/hydra/tmp/images"
    FileUtils.mkdir_p(path)
    path
  end

  def convert_pdf_to_image(pdf_path, image_path, id)
    begin
      # First attempt with preferred settings
      MiniMagick::Tool::Convert.new do |convert|
        convert << "-density" << "300"
        convert << "-quality" << "100"
        convert << "-background" << "white"
        convert << "-alpha" << "remove"
        convert << "#{pdf_path}[0]"
        convert << "#{image_path}/#{id}.jpg"
      end
    rescue MiniMagick::Error => e
      Rails.logger.warn "Initial PDF conversion failed for #{id}, trying fallback method"
      
      # Fallback attempt with ghostscript
      MiniMagick::Tool::Convert.new do |convert|
        convert << "-density" << "300"
        convert << "-quality" << "100"
        convert << "-define" << "pdf:use-cropbox=true"
        convert << "-background" << "white"
        convert << "-alpha" << "remove"
        convert << "#{pdf_path}[0]"
        convert << "#{image_path}/#{id}.jpg"
      end
    rescue MiniMagick::Error => e
      Rails.logger.error "PDF conversion failed for #{id}: #{e.message}"
      raise e
    end
  end

  def find_image_path(id, base_path)
    if File.exist?("#{base_path}/#{id}.jpg")
      "#{base_path}/#{id}.jpg"
    elsif File.exist?("#{base_path}/#{id}-0.jpg")
      "#{base_path}/#{id}-0.jpg"
    else
      Rails.logger.error "No image generated for ID: #{id}"
      nil
    end
  end

  def create_thumbnail(id, image_path, record)
    thumbnail_path = "/home/hydra/tmp/thumbnails"
    FileUtils.mkdir_p(thumbnail_path)
    output_path = "#{thumbnail_path}/#{id}.jpg"
    
    begin
      Rails.logger.info "Starting thumbnail creation for ID: #{id}"
      MiniMagick::Tool::Convert.new do |convert|
        convert.resize '150x150>' # Back to smaller size for thumbnails
        convert.quality '100'
        convert << image_path
        convert << output_path
      end
      
      # Verify thumbnail was created successfully
      unless File.exist?(output_path) && File.size(output_path) > 0
        Rails.logger.error "Failed to create thumbnail at: #{output_path}"
        return false
      end
      
      Rails.logger.info "Thumbnail created successfully at: #{output_path}"
      ImportLibrary.set_file(record.build_thumbnail_file, 'application/jpg', output_path)
      record.queued_job = 'false'
      record.save!
    rescue MiniMagick::Error => e
      Rails.logger.error "Thumbnail conversion failed for #{id}: #{e.message}"
      return false
    rescue StandardError => e
      Rails.logger.error "Unexpected error creating thumbnail for #{id}: #{e.message}"
      return false
    end
  end

  def cleanup_files(id, original_path)
    Rails.logger.info "not cleaning up files while testing"
    paths = [
      "/home/hydra/tmp/pdf/#{id}.pdf",
      Dir.glob("/home/hydra/tmp/images/#{id}*"),
      Dir.glob("/home/hydra/tmp/thumbnails/#{id}*")
    ].flatten
    
    Rails.logger.info "Starting cleanup for ID: #{id}"
    paths.each do |path|
      if File.exist?(path)
        Rails.logger.info "Removing temporary file: #{path}"
        File.delete(path)
      end
    end
    Rails.logger.info "Cleanup completed for ID: #{id}"
  end
end
