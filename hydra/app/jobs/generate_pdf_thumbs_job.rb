class GeneratePdfThumbsJob < ApplicationJob
  include ImportLibrary

  queue_as :import

  def perform(identifier)
    # find record
    record = Acda.where(identifier: identifier).first

    # temp folder to store pdf files
    pdf_path = "/home/hydra/tmp/pdf"    

    # make folder if it doesn't exist
    FileUtils.mkdir_p(pdf_path) unless File.exist?(pdf_path)

    # add identifier and extension to pdf path so we have 
    # full path and file name to pdf file.
    pdf_path = "#{pdf_path}/#{identifier}.pdf"

    # download image file from preview url
    pdf_file = URI.open(record.preview)

    tempfile = File.new(pdf_path, "w+")
    IO.copy_stream(pdf_file, pdf_path)
    tempfile.close

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
      convert << tempfile.path
      # add path of page to be converted
      convert << "#{image_path}/#{identifier}.jpg"
    end  

    # check and see if image exists
    if File.exist?("#{image_path}/#{identifier}.jpg")
      # set image file
      image_path = "#{image_path}/#{identifier}.jpg"
    elsif File.exist?("#{image_path}/#{identifier}-0.jpg")
      # set image file
      image_path = "#{image_path}/#{identifier}-0.jpg"
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
      convert << "#{thumbnail_path}/#{identifier}.jpg"
    end    

    ImportLibrary.set_file(record.build_thumbnail_file, 'application/jpg', "#{thumbnail_path}/#{identifier}.jpg")
    record.save!

    # delete temp files
    # tempfile.unlink

    # delete downloaded pdf file
    File.delete(pdf_path) if File.exist?(pdf_path)

    # delete all images with identifier
    Dir.glob("#{image_path}/#{identifier}*").each do |file|  
      File.delete(file)
    end

    # delete thumbnails with identifier
    Dir.glob("#{thumbnail_path}/#{identifier}*").each do |file|
      File.delete(file)
    end
  end

end