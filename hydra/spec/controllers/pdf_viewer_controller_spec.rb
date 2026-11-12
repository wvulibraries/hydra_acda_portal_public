require 'rails_helper'

RSpec.describe PdfViewerController, type: :controller do
  describe 'GET #index' do
    let(:pdf_file) { double('PdfFileAttachment', download: 'PDFDATA') }
    let(:record) { double('CongressionalRecord', pdf_file: pdf_file) }
    before do
      allow(CongressionalRecord).to receive(:find_by).and_return(record)
      get :index, params: { id: '123.pdf' }
    end
    it 'responds with success' do
      expect(response).to be_successful
    end
    it 'sends PDF data' do
      expect(response.body).to eq('PDFDATA')
      expect(response.header['Content-Type']).to eq('application/pdf')
    end
  end
end