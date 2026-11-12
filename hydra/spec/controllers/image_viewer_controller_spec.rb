require 'rails_helper'

RSpec.describe ImageViewerController, type: :controller do
  describe 'GET #index' do
    let(:image_file) { double('ImageFileAttachment', attached?: true, download: 'IMAGEDATA') }
    let(:record) { double('CongressionalRecord', image_file: image_file) }
    before do
      allow(CongressionalRecord).to receive(:find_by).and_return(record)
      get :index, params: { id: '123.jpg' }
    end
    it 'responds with success' do
      expect(response).to be_successful
    end
    it 'renders image data' do
      expect(response.body).to include('IMAGEDATA')
    end
  end

  describe 'GET #thumb' do
    let(:thumbnail_file) { double('ThumbFileAttachment', attached?: true, download: 'THUMBDATA') }
    let(:record) { double('CongressionalRecord', thumbnail_file: thumbnail_file) }
    before do
      allow(CongressionalRecord).to receive(:find_by).and_return(record)
      get :thumb, params: { id: '123.jpg' }
    end
    it 'responds with success' do
      expect(response).to be_successful
    end
    it 'renders thumb data' do
      expect(response.body).to include('THUMBDATA')
    end
  end
end