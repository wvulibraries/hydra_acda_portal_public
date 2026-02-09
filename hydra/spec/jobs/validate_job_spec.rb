require 'rails_helper'

RSpec.describe ValidateJob, type: :job do
  let(:path) { '/tmp/test.csv' }
  let(:file_name) { 'test.csv' }
  let(:mail_to) { 'test@example.com' }
  let(:validate_urls) { false }
  let(:validation_content) { { success: true, errors: [] } }

  before do
    allow_any_instance_of(ValidationService).to receive(:validate).and_return(validation_content)
    allow(ValidationMailer).to receive_message_chain(:email_validation, :deliver_now)
  end

  describe '#perform' do
    it 'calls ValidationService with correct parameters' do
      expect(ValidationService).to receive(:new).with(path: path, validate_urls: validate_urls).and_call_original

      ValidateJob.perform_now(path: path, file_name: file_name, mail_to: mail_to, validate_urls: validate_urls)
    end

    it 'sends validation email' do
      expect(ValidationMailer).to receive(:email_validation).with(
        mail_to: mail_to,
        file_name: file_name,
        content: validation_content
      ).and_return(double(deliver_now: true))

      ValidateJob.perform_now(path: path, file_name: file_name, mail_to: mail_to, validate_urls: validate_urls)
    end

    it 'deletes the file after processing' do
      allow(File).to receive(:exist?).with(path).and_return(true)
      expect(File).to receive(:delete).with(path)

      ValidateJob.perform_now(path: path, file_name: file_name, mail_to: mail_to, validate_urls: validate_urls)
    end

    it 'handles email timeout gracefully' do
      allow(ValidationMailer).to receive_message_chain(:email_validation, :deliver_now).and_raise(Net::OpenTimeout)

      expect(Rails.logger).to receive(:error).with(/Emailer may not be set up correctly/)

      # Should not raise an error
      expect {
        ValidateJob.perform_now(path: path, file_name: file_name, mail_to: mail_to, validate_urls: validate_urls)
      }.not_to raise_error
    end
  end

  describe 'queue' do
    it 'is queued as default' do
      expect(ValidateJob.queue_name).to eq('default')
    end
  end
end