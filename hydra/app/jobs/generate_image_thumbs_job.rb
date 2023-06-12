class GenerateImageThumbsJob < ApplicationJob
  include ImportLibrary

  queue_as :import

  def perform(identifier)
    # find record
    record = Acda.where(identifier: identifier).first

    # set image file
    image_path = "/home/hydra/tmp/images/#{identifier}.jpg"

    # download image file from preview url
    image_file = URI.open(record.preview)

    tempfile = File.new(image_path, "w+")
    IO.copy_stream(image_file, image_path)
    tempfile.close

    record.files.build unless record.files.present?

    # if image file exists set image file and create thumbnail
    if File.exist?(image_path)   
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
    end   

    # check and see if thumbnail exists
    if File.exist?("#{thumbnail_path}/#{identifier}.jpg")
      # set thumbnail file 
      ImportLibrary.set_file(record.build_thumbnail_file, 'application/jpg', "#{thumbnail_path}/#{identifier}.jpg")
    end
    
    record.save!

    # cleanup section

    # delete thumbnails with identifer
    Dir.glob("#{image_path}/#{identifier}*").each do |file|
      File.delete(file)
    end

    # delete thumbnails with identifer
    Dir.glob("#{thumbnail_path}/#{identifier}*").each do |file|
      File.delete(file)
    end
  end

end