require 'rails_helper'

RSpec.describe PdfViewerController, type: :controller do
  describe 'GET #index' do
    let(:acda) { double('Acda', pdf_file: double('PdfFile', content: 'PDFDATA')) }
    before do
      allow(Acda).to receive(:where).and_return([acda])
      allow(acda).to receive(:pdf_file).and_return(double('PdfFile', content: 'PDFDATA'))
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
