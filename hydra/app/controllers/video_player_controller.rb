# Video Player Class
class VideoPlayerController < ApplicationController
  def index
    id = File.basename(params[:id], File.extname(params[:id]))
    image_model = Acda.where(id: id).first
    @mime = image_model.video_file.mime_type
    @video = image_model.video_file.content
    send_data @video, filename: id, type: @mime, disposition: 'inline'
  end
end
