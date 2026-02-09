require 'rails_helper'

RSpec.describe ApplicationMailer, type: :mailer do
  describe 'default configuration' do
    it 'has the correct default from address' do
      expect(described_class.default_params[:from]).to eq('libdev@mail.wvu.edu')
    end

    it 'inherits from ActionMailer::Base' do
      expect(described_class.superclass).to eq(ActionMailer::Base)
    end
  end
end