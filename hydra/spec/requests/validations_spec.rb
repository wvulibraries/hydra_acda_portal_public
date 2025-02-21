require 'rails_helper'

RSpec.describe "Validations", type: :request do
  include ActionDispatch::TestProcess

  let(:valid_csv) do
    fixture_file_upload(
      Rails.root.join("spec/fixtures/validation_service_fixtures/valid.csv"),
      'text/csv'
    )
  end

  let(:invalid_file) do
    fixture_file_upload(
      Rails.root.join("spec/fixtures/validation_service_fixtures/test.txt"),
      'text/plain'
    )
  end

  let(:user) { create(:user) }
  let(:validation_results) { [] }
  let(:validation_service) { instance_double(ValidationService, validate: validation_results) }

  before do
    # Make sure Devise is configured for testing
    allow_any_instance_of(ValidationsController).to receive(:authenticate_user!).and_return(true)
    allow_any_instance_of(ValidationsController).to receive(:current_user).and_return(user)
    
    # Setup service mocks
    allow(ValidationService).to receive(:new).and_return(validation_service)
    allow(File).to receive(:delete).and_return(true)
    allow(FileUtils).to receive(:cp).and_return(true)
    
    # Setup tempfile mock
    allow_any_instance_of(ActionDispatch::Http::UploadedFile)
      .to receive(:tempfile)
      .and_return(double('tempfile', path: '/tmp/test.csv'))
  end

  describe "GET /validate" do
    it "renders the upload form" do
      get validate_path
      expect(response).to be_successful
      expect(response).to render_template(:upload)
    end
  end

  describe "POST /validate" do
    context "with no file" do
      it "redirects with error message" do
        post validate_path
        expect(response).to redirect_to(validate_path)
        expect(flash[:error]).to eq('Please upload a CSV file')
      end
    end

    context "with non-CSV file" do
      it "redirects with error message" do
        post validate_path, params: { csv_file: invalid_file }
        expect(response).to redirect_to(validate_path)
        expect(flash[:error]).to eq('Please upload a CSV file')
      end
    end

    context "with valid CSV file" do
      context "when running immediate validation" do
        let(:params) { { csv_file: valid_csv } }

        it "shows validation results" do
          post validate_path, params: params
          expect(response).to be_successful
          expect(assigns(:results)).to eq validation_results
        end

        it "validates URLs when option is selected" do
          post validate_path, params: params.merge(validate_urls: "1")
          expect(ValidationService).to have_received(:new)
            .with(hash_including(validate_urls: true))
        end

        it "cleans up temporary file after validation" do
          post validate_path, params: params
          expect(File).to have_received(:delete)
        end
      end

      context "when running as background job" do
        before do
          allow(ValidateJob).to receive(:perform_later)
        end

        it "enqueues job and redirects" do
          post validate_path, params: { 
            csv_file: valid_csv,
            background_job: "1",
            mail_to: "test@example.com"
          }

          expect(ValidateJob).to have_received(:perform_later)
            .with(hash_including(
              mail_to: "test@example.com",
              file_name: valid_csv.original_filename
            ))

          expect(response).to redirect_to(validate_path)
          expect(flash[:notice]).to match(/job has been submitted/i)
        end
      end
    end

    context "with malformed CSV" do
      before do
        allow(validation_service)
          .to receive(:validate)
          .and_raise(CSV::MalformedCSVError.new("test error", 1))
      end

      it "redirects with error message" do
        post validate_path, params: { csv_file: valid_csv }
        expect(response).to redirect_to(validate_path)
        expect(flash[:error]).to eq('Invalid CSV file format')
      end
    end
  end
end