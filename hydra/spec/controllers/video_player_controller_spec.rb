require 'rails_helper'

RSpec.describe VideoPlayerController, type: :controller do
  describe 'GET #index' do
    let(:video_file) { double('VideoFileAttachment', content_type: 'video/mp4', download: 'VIDEODATA') }
    let(:record) { double('CongressionalRecord', video_file: video_file) }
    before do
      allow(CongressionalRecord).to receive(:find_by).and_return(record)
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