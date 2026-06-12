require 'rails_helper'

RSpec.describe ValidationMailer, type: :mailer do
  describe '.email_validation' do
    let(:mail) { described_class.email_validation(mail_to: 'user@example.com', file_name: 'test.csv', content: 'Some content') }

    it 'renders the subject' do
      expect(mail.subject).to eq('Validation results for file: test.csv')
    end

    it 'sends to the correct recipient' do
      expect(mail.to).to eq(['user@example.com'])
    end

    it 'includes the content in the body' do
      expect(mail.body.encoded).to include('Some content')
    end
  end
end
