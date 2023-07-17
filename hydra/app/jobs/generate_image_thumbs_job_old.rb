class GenerateImageThumbsJob < ApplicationJob
  include ImportLibrary

  queue_as :import

  def perform(identifier)
    # find record
    record = Acda.where(identifier: identifier).first

    # set image path
    image_path = "/home/hydra/tmp/images"  
    
    page = Nokogiri::HTML(URI.open(record.preview))

    image_path = "#{image_path}/#{identifier}.jpg"

    if page.css('div#content a')[0].values[0] == "download-file"
      # download image file from extracted url
      image_file = URI.open(page.css('div#content a')[0].values[1])
      download_image_file = File.new(image_path, "w+")
      IO.copy_stream(image_file, download_image_file.path)
      download_image_file.close
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
  end

end