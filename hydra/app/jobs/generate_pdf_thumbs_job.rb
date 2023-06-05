class GeneratePdfThumbsJob < ApplicationJob
  include ImportLibrary

  queue_as :import

  def perform(identifier)
    # find record
    record = Acda.where(identifier: identifier).first

    # set temp folder path
    temp_path = "/home/hydra/tmp"

    # set download path
    downloads_path = "#{temp_path}/downloads"  

    # download pdf file from preview url
    pdf_file = URI.open(record.preview)
    pdftempfile = Tempfile.new([identifier, '.pdf'], downloads_path)
    IO.copy_stream(pdf_file, pdftempfile.path)
    pdftempfile.close

    record.files.build unless record.files.present?

    # set image path
    image_path = "/home/hydra/tmp/images"

    MiniMagick::Tool::Convert.new do |convert|
      # prep format
      convert.format 'jpg'
      convert.background "white"
      # convert.flatten
      convert.density 300
      convert.quality 100
      # add page to be converted
      convert << pdftempfile.path
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
    pdftempfile.unlink

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