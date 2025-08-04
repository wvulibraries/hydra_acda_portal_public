require 'rails_helper'

RSpec.describe ImageViewerController, type: :controller do
  describe 'GET #index' do
    let(:acda) { double('Acda', image_file: double('ImageFile', content: 'IMAGEDATA')) }
    before do
      allow(Acda).to receive(:where).and_return([acda])
      allow(acda).to receive(:image_file).and_return(double('ImageFile', content: 'IMAGEDATA'))
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
    let(:acda) { double('Acda', thumbnail_file: double('ThumbFile', content: 'THUMBDATA')) }
    before do
      allow(Acda).to receive(:where).and_return([acda])
      allow(acda).to receive(:thumbnail_file).and_return(double('ThumbFile', content: 'THUMBDATA'))
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
