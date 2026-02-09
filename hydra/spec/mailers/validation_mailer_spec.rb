require 'rails_helper'

RSpec.describe ValidationMailer, type: :mailer do
  describe '#email_validation' do
    let(:mail_to) { 'test@example.com' }
    let(:file_name) { 'test_file.csv' }
    let(:content) { 'Validation results content' }

    it 'creates a mail object' do
      # Test that the method exists and can be called without errors
      expect { ValidationMailer.email_validation(mail_to: mail_to, file_name: file_name, content: content) }.not_to raise_error
    end
  end
end