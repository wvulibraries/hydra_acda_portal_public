class GenerateImageThumbsJob < ApplicationJob
  include ImportLibrary

  queue_as :import

  def perform(id, download_path)
    return unless File.exist? download_path

    # find record
    record = Acda.where(id: id).first
    # temp folder to store images
    image_path = "/home/hydra/tmp/images"

    # make folder if it doesn't exist
    FileUtils.mkdir_p(image_path) unless File.exist?(image_path)

    # add id and extension to image path so we have
    # full path and file name to image file.
    image_path = "#{image_path}/#{id}.jpg"
    # moves the already downloaded file to the expected path
    FileUtils.mv(download_path, image_path)
    # create folder if it doesn't exist
    FileUtils.mkdir_p(image_path) unless File.exist?(image_path)

    record.files.build unless record.files.present?

    # if image file exists set image file and create thumbnail
    if File.exist?(image_path)
      ImportLibrary.set_file(record.build_image_file, 'application/jpg', image_path)
      # set thumbnail path
      thumbnail_path = "/home/hydra/tmp/thumbnails"

      MiniMagick::Tool::Convert.new do |convert|
        convert.thumbnail '400x400>'  # Larger size with aspect ratio preservation
        convert.format 'jpg'
        convert.background "white"
        convert.density 300          # Keep high DPI for better quality
        convert.quality 95           # High quality, reasonable file size
        convert << image_path
        convert << "#{thumbnail_path}/#{id}.jpg"
      end
    end

    # check and see if thumbnail exists
    if File.exist?("#{thumbnail_path}/#{id}.jpg")
      # set thumbnail file
      ImportLibrary.set_file(record.build_thumbnail_file, 'application/jpg', "#{thumbnail_path}/#{id}.jpg")
    end

    record.save!

    # delete temp files
    # imagefile.unlink

    # delete downloaded image file
    File.delete(image_path) if File.exist?(image_path)

    # delete thumbnails with identifer
    Dir.glob("#{File.dirname(image_path)}/#{id}*").each do |file|
      File.delete(file)
    end

    # delete thumbnails with identifer
    Dir.glob("#{thumbnail_path}/#{id}*").each do |file|
      File.delete(file)
    end
  end
end
