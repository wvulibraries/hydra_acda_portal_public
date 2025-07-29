require 'rails_helper'

RSpec.describe ApplicationMailer, type: :mailer do
  it 'inherits from ActionMailer::Base' do
    expect(ApplicationMailer.superclass).to eq(ActionMailer::Base)
  end
end
