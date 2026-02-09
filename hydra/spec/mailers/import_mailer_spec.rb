require 'rails_helper'

RSpec.describe ImportMailer, type: :mailer do
  describe '#email' do
    let(:to_address) { 'test@example.com' }
    let(:subject) { 'Test Subject' }
    let(:body) { 'Test body content' }
    let(:mail) { ImportMailer.email(to_address, subject, body) }

    it 'renders the headers' do
      expect(mail.subject).to eq(subject)
      expect(mail.to).to eq([to_address])
      expect(mail.from).to eq(['libdev@mail.wvu.edu'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include(body)
    end
  end
end