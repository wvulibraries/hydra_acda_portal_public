# Pdf Viewer Class
class PdfViewerController < ApplicationController
  def index
    id = File.basename(params[:id], File.extname(params[:id]))
    image_model = Acda.where(id: id).first
    @pdf = image_model.pdf_file.content
    send_data @pdf, filename: id, type: 'application/pdf', disposition: 'inline'
  end
end
