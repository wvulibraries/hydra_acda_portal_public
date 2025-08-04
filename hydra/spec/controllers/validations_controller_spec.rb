require 'rails_helper'

RSpec.describe ValidationsController, type: :controller do
  describe 'POST #show' do
    let(:csv_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/dummy.csv'), 'text/csv') }
    let(:not_csv_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/dummy.txt'), 'text/plain') }
    before do
      allow(FileUtils).to receive(:cp)
      allow(File).to receive(:delete)
      allow(ValidationService).to receive_message_chain(:new, :validate).and_return('results')
    end
    it 'redirects with error if not csv' do
      post :show, params: { csv_file: not_csv_file }
      expect(flash[:error]).to be_present
      expect(response).to redirect_to(validate_path)
    end
    
    it 'submits job if background_job is 1' do
      allow(ValidateJob).to receive(:perform_later)
      post :show, params: { csv_file: csv_file, background_job: '1', mail_to: 'a@b.com', validate_urls: '0' }
      expect(flash[:notice]).to be_present
      expect(response).to redirect_to(validate_path)
    end
    
  end
end
