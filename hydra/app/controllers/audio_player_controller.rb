# Audio Player Class
class AudioPlayerController < ApplicationController
  def index
    id = File.basename(params[:id], File.extname(params[:id]))
    record = CongressionalRecord.find_by(id: id)
    @mime = record.audio_file.content_type
    @audio = record.audio_file.download
    send_data @audio, filename: id, type: @mime, disposition: 'inline'
  end
end
