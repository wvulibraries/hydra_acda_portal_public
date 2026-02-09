require 'rails_helper'

RSpec.describe SearchHistoryController, type: :controller do
  # Basic test for controller existence and inheritance
  it 'inherits from ApplicationController' do
    expect(described_class.superclass).to eq(ApplicationController)
  end

  it 'includes Blacklight::SearchHistory' do
    expect(described_class.ancestors).to include(Blacklight::SearchHistory)
  end
end