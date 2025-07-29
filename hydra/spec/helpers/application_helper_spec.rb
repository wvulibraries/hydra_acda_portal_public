require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#application_name' do
    it 'returns the portal name' do
      expect(helper.application_name).to eq('American Congress Digital Archives Portal')
    end
  end

  describe '#application_header' do
    it 'returns the portal header' do
      expect(helper.application_header).to eq('American Congress Digital Archives Portal')
    end
  end

  describe '#render_page_description' do
    it 'returns the page description' do
      expect(helper.render_page_description).to include('collaborative, non-partisan project')
    end
  end

  describe '#render_key_words' do
    it 'returns the key words' do
      expect(helper.render_key_words).to include('congress')
    end
  end

  describe '#catalog_page_render' do
    it 'returns search_results if params present' do
      allow(helper).to receive(:params).and_return({ q: 'test' })
      expect(helper.catalog_page_render).to eq('search_results')
    end
    it 'returns home_text if no params' do
      allow(helper).to receive(:params).and_return({})
      expect(helper.catalog_page_render).to eq('home_text')
    end
  end

  # Add more tests for other helper methods as needed
end
