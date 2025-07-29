require 'rails_helper'

RSpec.describe RecordMailer, type: :mailer do
  describe '.record_notification' do
    let(:mail) { described_class.record_notification(mail_to: 'user@example.com', record_id: '123', message: 'Record updated') }

    it 'renders the subject' do
      expect(mail.subject).to include('123')
    end

    it 'sends to the correct recipient' do
      expect(mail.to).to eq(['user@example.com'])
    end

    it 'includes the message in the body' do
      expect(mail.body.encoded).to include('Record updated')
    end
  end
end
