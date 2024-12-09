# Image Viewer Class
class ImageViewerController < ApplicationController
  ## gets image and shows image
  def index
    id = File.basename(params[:id], File.extname(params[:id]))
    image_model = Acda.where(id: id).first

    if image_model.image_file
      @image = image_model.image_file.content
    else
      # we need to display a default image
      @image = File.open(Rails.root.join('app', 'assets', 'images', 'no-image.png')).read
    end

    render inline: "<%= raw @image %>", layout: false
  end

  ## gets image and shows image
  def thumb
    id = File.basename(params[:id], File.extname(params[:id]))
    image_model = Acda.where(id: id).first

    if image_model.thumbnail_file
      @thumb = image_model.thumbnail_file.content
    else
      # we need to display a default image
      @thumb = File.open(Rails.root.join('app', 'assets', 'images', 'no-image.png')).read
    end

    render inline: "<%= raw @thumb %>", layout: false
  end
end