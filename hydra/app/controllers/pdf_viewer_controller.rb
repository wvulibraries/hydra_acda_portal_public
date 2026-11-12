# Pdf Viewer Class
class PdfViewerController < ApplicationController
  def index
    id = File.basename(params[:id], File.extname(params[:id]))
    record = CongressionalRecord.find_by(id: id)
    @pdf = record.pdf_file.download
    send_data @pdf, filename: id, type: 'application/pdf', disposition: 'inline'
  end
end