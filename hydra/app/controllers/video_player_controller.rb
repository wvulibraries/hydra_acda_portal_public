# Video Player Class
class VideoPlayerController < ApplicationController
  def index
    id = File.basename(params[:id], File.extname(params[:id]))
    record = CongressionalRecord.find_by(id: id)
    @mime = record.video_file.content_type
    @video = record.video_file.download
    send_data @video, filename: id, type: @mime, disposition: 'inline'
  end
end