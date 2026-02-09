require 'rails_helper'

RSpec.describe VideoPlayerController, type: :controller do
  let(:acda_record) { build(:acda) }

  describe 'GET #index' do
    before do
      allow(Acda).to receive(:where).and_return([acda_record])
      allow(acda_record).to receive(:video_file).and_return(double(mime_type: 'video/mp4', content: 'video content'))
    end

    it 'sends the video file' do
      get :index, params: { id: acda_record.id }
      expect(response).to have_http_status(:success)
      expect(response.headers['Content-Disposition']).to include('inline')
    end
  end
end