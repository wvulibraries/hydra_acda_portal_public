require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#application_name' do
    it 'returns the correct application name' do
      expect(helper.application_name).to eq('American Congress Digital Archives Portal')
    end
  end

  describe '#application_header' do
    it 'returns the correct application header' do
      expect(helper.application_header).to eq('American Congress Digital Archives Portal')
    end
  end

  describe '#render_page_description' do
    it 'returns the correct page description' do
      expected_description = 'The American Congress Digital Archives Portal is a collaborative, non-partisan project that aggregates congressional archives held by multiple institutions and makes the archives available online.'
      expect(helper.render_page_description).to eq(expected_description)
    end
  end

  describe '#render_key_words' do
    it 'returns the correct keywords' do
      expect(helper.render_key_words).to eq('congress, government, legislation, policy, politics')
    end
  end

  describe '#format_url' do
    it 'returns the url unchanged if blank' do
      expect(helper.format_url('')).to eq('')
      expect(helper.format_url(nil)).to eq(nil)
    end

    it 'adds https scheme if missing' do
      expect(helper.format_url('example.com')).to eq('https://example.com')
    end

    it 'returns https urls unchanged' do
      expect(helper.format_url('https://example.com')).to eq('https://example.com')
    end

    it 'converts http urls to https' do
      expect(helper.format_url('http://example.com')).to eq('https://example.com')
    end
  end

  describe '#catalog_page_render' do
    it 'returns search_results when search params are present' do
      allow(helper).to receive(:params).and_return({ q: 'test' })
      expect(helper.catalog_page_render).to eq('search_results')
    end

    it 'returns home_text when no search params' do
      allow(helper).to receive(:params).and_return({})
      expect(helper.catalog_page_render).to eq('home_text')
    end
  end

  describe '#sanitize_url' do
    it 'normalizes the url' do
      expect(helper.sanitize_url('http://example.com/path')).to eq('http://example.com/path')
    end
  end
end