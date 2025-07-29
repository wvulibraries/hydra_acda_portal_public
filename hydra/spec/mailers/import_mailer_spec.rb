require 'rails_helper'

RSpec.describe ImportMailer, type: :mailer do
  describe '.import_notification' do
    let(:mail) { described_class.import_notification(mail_to: 'user@example.com', file_name: 'import.csv', status: 'Success') }

    it 'renders the subject' do
      expect(mail.subject).to include('import.csv')
    end

    it 'sends to the correct recipient' do
      expect(mail.to).to eq(['user@example.com'])
    end

    it 'includes the status in the body' do
      expect(mail.body.encoded).to include('Success')
    end
  end
end
