class GenerateThumbsJob < ApplicationJob
  queue_as :import

  # we are passing in the Fedora object's id instead of identifier
  # because the identifier can have special characters which will be
  # problematic in file and folder creation
  def perform(id)
    # find record
    record = Acda.where(id: id).first
    # Ignore if record type is sound or moving image
    return if record.dc_type.nil?
    return if ((record.dc_type == 'Sound') || (record.dc_type.include? 'Moving'))
    return unset_image_and_thumbnail!(record) if record.preview.blank?

    # temp folder to store downloaded files
    file_path = "/home/hydra/tmp/download"

    # make folder if it doesn't exist
    FileUtils.mkdir_p(file_path) unless File.exist?(file_path)

    # add id to file path so we have full path and file name.
    download_path = "#{file_path}/#{id}"

    begin
      # download file from preview url
      file = URI.open(record.preview)
    rescue Errno::ENOENT => e
      Rails.logger.error "Error: edm:preview for #{record.identifier} is not a valid resource url. #{e.message}"
      return unset_image_and_thumbnail!(record)
    end

    tempfile = File.new(download_path, "w+")
    IO.copy_stream(file, download_path)
    tempfile.close

    # check if the tempfile is indeed a pdf or image
    mime_type = `file --brief --mime-type #{Shellwords.escape(download_path)}`.strip

    # sets thumbnail_file and image_file to nil if mime_type is not a pdf or image
    # so we don't retain the previous thumbnail_file and image_file
    if mime_type.include?('pdf')
      GeneratePdfThumbsJob.perform_later(id, download_path)
    elsif mime_type.include?('image')
      GenerateImageThumbsJob.perform_later(id, download_path)
    else
      return unset_image_and_thumbnail!(record)
    end
  end

  private

    def unset_image_and_thumbnail!(record)
      record.thumbnail_file = nil
      record.image_file = nil
      record.update_index
    end
end
