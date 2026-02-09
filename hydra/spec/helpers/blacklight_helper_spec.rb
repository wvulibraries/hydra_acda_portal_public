require 'rails_helper'

RSpec.describe BlacklightHelper, type: :helper do
  describe '#application_name' do
    it 'returns the correct application name' do
      expect(helper.application_name).to eq('American Congress Digital Archives Portal')
    end
  end

  describe '#extract_year' do
    it 'extracts year from YYYY-MM-DD format' do
      expect(helper.extract_year('2020-12-25')).to eq(2020)
    end

    it 'extracts year from YYYY-MM format' do
      expect(helper.extract_year('2020-12')).to eq(2020)
    end

    it 'extracts year from YYYY format' do
      expect(helper.extract_year('2020')).to eq(2020)
    end

    it 'returns the string unchanged if not a date format' do
      expect(helper.extract_year('not-a-date')).to eq('not-a-date')
    end
  end
end