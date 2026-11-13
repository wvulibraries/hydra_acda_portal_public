require 'rails_helper'

RSpec.describe AudioPlayerController, type: :controller do
  describe 'GET #index' do
    let(:audio_file) { double('AudioFileAttachment', content_type: 'audio/mpeg', download: 'AUDIODATA') }
    let(:record) { double('CongressionalRecord', audio_file: audio_file) }
    before do
      allow(CongressionalRecord).to receive(:find_by).and_return(record)
      get :index, params: { id: '123.mp3' }
    end
    it 'responds with success' do
      expect(response).to be_successful
    end
    it 'sends audio data' do
      expect(response.body).to eq('AUDIODATA')
      expect(response.header['Content-Type']).to eq('audio/mpeg')
    end
  end
end
