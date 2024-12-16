class DownloadAndSetThumbsJob < ApplicationJob
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

    # check if the tempfile is indeed an image
    mime_type = `file --brief --mime-type #{Shellwords.escape(download_path)}`.strip
    return unset_image_and_thumbnail!(record) unless mime_type.include?('image')

    ImportLibrary.set_file(record.build_thumbnail_file, 'application/jpg', "#{download_path}")
    record.save!

    # remove the downloaded file
    File.delete(download_path)
  end

  private

    def unset_image_and_thumbnail!(record)
      record.thumbnail_file = nil
      record.image_file = nil
      record.save
      record.update_index
    end
end
