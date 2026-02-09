require 'rails_helper'

RSpec.describe ImageViewerController, type: :controller do
  let(:acda_record) { build(:acda) }

  describe 'GET #index' do
    context 'when image exists' do
      before do
        allow(Acda).to receive(:where).and_return([acda_record])
        allow(acda_record).to receive(:image_file).and_return(double(content: 'image content'))
      end

      it 'returns the image content' do
        get :index, params: { id: acda_record.id }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to start_with('text/html')
      end
    end

    context 'when image does not exist' do
      before do
        allow(Acda).to receive(:where).and_return([acda_record])
        allow(acda_record).to receive(:image_file).and_return(nil)
      end

      it 'returns default no-image' do
        get :index, params: { id: acda_record.id }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET #thumb' do
    context 'when thumbnail exists' do
      before do
        allow(Acda).to receive(:where).and_return([acda_record])
        allow(acda_record).to receive(:thumbnail_file).and_return(double(content: 'thumb content'))
      end

      it 'returns the thumbnail content' do
        get :thumb, params: { id: acda_record.id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when thumbnail does not exist' do
      before do
        allow(Acda).to receive(:where).and_return([acda_record])
        allow(acda_record).to receive(:thumbnail_file).and_return(nil)
      end

      it 'returns default no-image' do
        get :thumb, params: { id: acda_record.id }
        expect(response).to have_http_status(:success)
      end
    end
  end
end