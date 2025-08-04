require 'rails_helper'

RSpec.describe VideoPlayerController, type: :controller do
  describe 'GET #index' do
    let(:video_file) { double('VideoFile', mime_type: 'video/mp4', content: 'VIDEODATA') }
    let(:acda) { double('Acda', video_file: video_file) }
    before do
      allow(Acda).to receive(:where).and_return([acda])
      get :index, params: { id: '123.mp4' }
    end
    it 'responds with success' do
      expect(response).to be_successful
    end
    it 'sends video data' do
      expect(response.body).to eq('VIDEODATA')
      expect(response.header['Content-Type']).to eq('video/mp4')
    end
  end
end
