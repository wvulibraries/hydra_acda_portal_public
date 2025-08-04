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

  describe '#render_html_safe_url' do
    it 'returns a link to the first value' do
      doc = { value: ['http://example.com'] }
      expect(helper.render_html_safe_url(doc)).to include('href="http://example.com"')
    end
  end

  describe '#render_thumbnail' do
    let(:doc) { double('Document', :[] => nil, :thumbnail_file? => false, :image_file? => false) }
    before do
      allow(helper).to receive(:link_to_document).and_return('<a class="image-slash">doc</a>')
      allow(helper).to receive(:render).and_return('partial')
    end
    it 'renders image slash if no thumbnail or image' do
      allow(doc).to receive(:[]).with(:dc_type_ssi).and_return('Text')
      expect(helper.render_thumbnail(doc)).to include('image-slash')
    end
    it 'renders audio button for Sound' do
      allow(helper).to receive(:link_to_document).and_return('<a class="audio-button">doc</a>')
      allow(doc).to receive(:[]).with(:dc_type_ssi).and_return('Sound')
      expect(helper.render_thumbnail(doc)).to include('audio-button')
    end
  end

  describe '#resolve_redirect' do
    it 'returns the url if no redirect' do
      allow(Net::HTTP).to receive(:get_response).and_return(double('Response', is_a?: false))
      expect(helper.resolve_redirect('http://example.com')).to eq('http://example.com/')
    end
  end

  describe '#sanitize_url' do
    it 'normalizes a url' do
      expect(helper.sanitize_url('http://example.com/../foo')).to include('foo')
    end
  end

  describe '#record_has_thumbnail?' do
    it 'returns true if record has thumbnail' do
      record = double('Acda', thumbnail_file: double('Thumb'))
      allow(Acda).to receive(:find).and_return(record)
      expect(helper.record_has_thumbnail?('id')).to eq(true)
    end
    it 'returns false if record has no thumbnail' do
      record = double('Acda', thumbnail_file: nil)
      allow(Acda).to receive(:find).and_return(record)
      expect(helper.record_has_thumbnail?('id')).to eq(false)
    end
  end
end
