require 'rails_helper'

RSpec.describe PdfViewerController, type: :controller do
  let(:acda_record) { build(:acda) }

  describe 'GET #index' do
    before do
      allow(Acda).to receive(:where).and_return([acda_record])
      allow(acda_record).to receive(:pdf_file).and_return(double(content: 'pdf content'))
    end

    it 'sends the PDF file' do
      get :index, params: { id: acda_record.id }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/pdf')
      expect(response.headers['Content-Disposition']).to include('inline')
    end
  end
end