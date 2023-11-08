class GeneratePdfThumbsJob < ApplicationJob
  include ImportLibrary

  queue_as :import

  def perform(id, download_path)
    return unless File.exist? download_path

    # find record
    record = Acda.where(id: id).first
    # temp folder to store pdf files
    pdf_dir = "/home/hydra/tmp/pdf"

    # make folder if it doesn't exist and move pdf file to folder
    FileUtils.mkdir_p(pdf_dir) unless File.exist?(pdf_dir)

    pdf_path = "#{pdf_dir}/#{id}.pdf"
    # moves the already downloaded file to the expected path
    FileUtils.mv(download_path, pdf_path)

    record.files.build unless record.files.present?

    # set image path
    image_path = "/home/hydra/tmp/images"

    # create folder if it doesn't exist
    FileUtils.mkdir_p(image_path) unless File.exist?(image_path)

    MiniMagick::Tool::Convert.new do |convert|
      # prep format
      convert.format 'jpg'
      convert.background "white"
      # convert.flatten
      convert.density 300
      convert.quality 100
      # add page to be converted
      convert << pdf_path
      # add path of page to be converted
      convert << "#{image_path}/#{id}.jpg"
    end

    # check and see if image exists
    if File.exist?("#{image_path}/#{id}.jpg")
      # set image file
      image_path = "#{image_path}/#{id}.jpg"
    elsif File.exist?("#{image_path}/#{id}-0.jpg")
      # set image file
      image_path = "#{image_path}/#{id}-0.jpg"
    end

    ImportLibrary.set_file(record.build_image_file, 'application/jpg', image_path)

    # set thumbnail path
    thumbnail_path = "/home/hydra/tmp/thumbnails"

    # create folder if it doesn't exist
    FileUtils.mkdir_p(thumbnail_path) unless File.exist?(thumbnail_path)

    MiniMagick::Tool::Convert.new do |convert|
      # prep format
      convert.thumbnail '150x150'
      convert.format 'jpg'
      convert.background "white"
      # convert.flatten
      convert.density 300
      convert.quality 100
      # add page to be converted
      convert << image_path
      # add path of page to be converted
      convert << "#{thumbnail_path}/#{id}.jpg"
    end

    ImportLibrary.set_file(record.build_thumbnail_file, 'application/jpg', "#{thumbnail_path}/#{id}.jpg")
    record.save!

    # delete downloaded pdf file
    File.delete(pdf_path) if File.exist?(pdf_path)

    # delete all images with id
    Dir.glob("#{image_path}/#{id}*").each do |file|
      File.delete(file)
    end

    # delete thumbnails with id
    Dir.glob("#{thumbnail_path}/#{id}*").each do |file|
      File.delete(file)
    end
  end
end
