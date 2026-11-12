# Image Viewer Class
class ImageViewerController < ApplicationController
  ## gets image and shows image
  def index
    id = File.basename(params[:id], File.extname(params[:id]))
    record = CongressionalRecord.find_by(id: id)

    if record&.image_file&.attached?
      @image = record.image_file.download
    else
      # we need to display a default image
      @image = File.open(Rails.root.join('app', 'assets', 'images', 'no-image.png')).read
    end

    render inline: "<%= raw @image %>", layout: false
  end

  ## gets image and shows image
  def thumb
    id = File.basename(params[:id], File.extname(params[:id]))
    record = CongressionalRecord.find_by(id: id)

    if record&.thumbnail_file&.attached?
      @thumb = record.thumbnail_file.download
    else
      # we need to display a default image
      @thumb = File.open(Rails.root.join('app', 'assets', 'images', 'no-image.png')).read
    end

    render inline: "<%= raw @thumb %>", layout: false
  end
end