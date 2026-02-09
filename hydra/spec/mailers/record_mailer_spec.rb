require 'rails_helper'

RSpec.describe RecordMailer, type: :mailer do
  let(:document) { double('document', to_semantic_values: { title: ['Test Document'] }) }
  let(:documents) { [document] }
  let(:details) { { to: 'test@example.com', message: 'Test message' } }
  let(:url_gen_params) { { host: 'example.com' } }

  describe '#email_record' do
    it 'creates a mail object' do
      # Test that the method exists and can be called without errors
      expect { RecordMailer.email_record(documents, details, url_gen_params) }.not_to raise_error
    end

    it 'has the correct default from address' do
      expect(described_class.default_params[:from]).to eq('libdev@mail.wvu.edu')
    end
  end
end