require 'rails_helper'

RSpec.describe ValidationsController, type: :controller do
  describe 'GET #upload' do
    it 'returns success' do
      get :upload
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #show' do
    let(:csv_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'test.csv'), 'text/csv') }

    context 'with valid CSV file' do
      it 'validates the file synchronously' do
        allow_any_instance_of(ValidationService).to receive(:validate).and_return({ success: true })
        post :show, params: { csv_file: csv_file, validate_urls: '0' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with background job' do
      it 'submits validation job' do
        expect(ValidateJob).to receive(:perform_later)
        post :show, params: { csv_file: csv_file, background_job: '1', mail_to: 'test@example.com' }
        expect(response).to redirect_to(validate_path)
        expect(flash[:notice]).to be_present
      end
    end

    context 'with invalid file type' do
      let(:invalid_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'test.csv'), 'text/plain') }

      it 'redirects with error' do
        post :show, params: { csv_file: invalid_file }
        expect(response).to redirect_to(validate_path)
        expect(flash[:error]).to eq('Please upload a CSV file')
      end
    end
  end
end