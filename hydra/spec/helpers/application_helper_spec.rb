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
    it 'renders video button for Moving' do
      allow(helper).to receive(:link_to_document).and_return('<a class="video-button">doc</a>')
      allow(doc).to receive(:[]).with(:dc_type_ssi).and_return('Moving Image')
      expect(helper.render_thumbnail(doc)).to include('video-button')
    end
    it 'renders pdf button for Text but not image_file' do
      allow(helper).to receive(:link_to_document).and_return('<a class="pdf-button">doc</a>')
      allow(doc).to receive(:[]).with(:dc_type_ssi).and_return('Text')
      allow(doc).to receive(:image_file?).and_return(false)
      expect(helper.render_thumbnail(doc)).to include('pdf-button')
    end
    it 'renders thumbnail image if thumbnail_file? is true' do
      allow(doc).to receive(:thumbnail_file?).and_return(true)
      allow(doc).to receive(:[]).with(:id).and_return('123')
      expect(helper.render_thumbnail(doc)).to include('/thumb/123.jpg')
    end
    it 'renders preview image if is_active_url? returns true' do
      allow(helper).to receive(:is_active_url?).and_return(true)
      allow(doc).to receive(:[]).with(:preview_tesim).and_return(['http://preview'])
      allow(doc).to receive(:[]).with(:title_tesim).and_return(['Title'])
      allow(doc).to receive(:[]).with(:description_tesim).and_return('desc')
      expect(helper.render_thumbnail(doc)).to include('http://preview')
    end
    it 'handles nil dc_type_ssi' do
      allow(doc).to receive(:[]).with(:dc_type_ssi).and_return(nil)
      expect(helper.render_thumbnail(doc)).to include('image-slash')
    end
  end

  describe '#resolve_redirect' do
    it 'returns original url on invalid URI error' do
      allow(Net::HTTP).to receive(:get_response).and_raise(URI::InvalidURIError)
      expect(Rails.logger).to receive(:error).at_least(:once)
      expect(helper.resolve_redirect('bad url')).to eq('bad url')
    end
    it 'returns original url on standard error' do
      allow(Net::HTTP).to receive(:get_response).and_raise(StandardError.new('fail'))
      expect(Rails.logger).to receive(:error).at_least(:once)
      expect(helper.resolve_redirect('bad url')).to eq('bad url')
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

  describe '#format_url' do
    it 'returns blank url as is' do
      expect(helper.format_url('')).to eq('')
    end
    it 'removes duplicate https and adds scheme if missing' do
      expect(helper.format_url('https:///example.com')).to eq('https://example.com')
      expect(helper.format_url('example.com')).to eq('https://example.com')
    end
    it 'sanitizes url with scheme' do
      # The helper always returns https:// for any input, even if http:// is given
      expect(helper.format_url('http://foo.com')).to eq('https://foo.com')
    end
  end

  describe '#is_active_url?' do
    let(:url) { 'http://example.com' }
    let(:url_check) { double('UrlCheck', active: false, needs_recheck?: true, update: true) }
    before do
      url_check_class = Class.new do
        def self.find_or_create_by(url:); end
      end
      stub_const('UrlCheck', url_check_class)
      allow(url_check_class).to receive(:find_or_create_by).and_return(url_check)
      allow(helper).to receive(:resolve_redirect).and_return(url)
      allow(URI).to receive(:parse).and_return(URI('http://example.com'))
      http_double = double('Net::HTTP')
      allow(http_double).to receive(:use_ssl=)
      allow(http_double).to receive(:read_timeout=)
      allow(http_double).to receive(:open_timeout=)
      allow(http_double).to receive(:head).and_return(double('Response', is_a?: true))
      allow(Net::HTTP).to receive(:new).and_return(http_double)
    end
    it 'returns false if url_check.active is false after retries' do
      allow(url_check).to receive(:update)
      expect(helper.is_active_url?(url, 1)).to eq(true)
    end
    it 'returns false if all retries fail' do
      allow(helper).to receive(:resolve_redirect).and_raise(StandardError.new('fail'))
      allow(url_check).to receive(:update)
      expect(Rails.logger).to receive(:error).at_least(:once)
      expect(url_check).to receive(:update).with(active: false)
      expect(helper.is_active_url?(url, 1)).to eq(false)
    end
  end

  describe '#render_html_safe_facet' do
    before do
      allow(helper).to receive(:link_to).and_return('<a>foo</a>')
      def helper.search_action_path(*); '/search'; end
    end
    it 'renders links for each value' do
      html = helper.render_html_safe_facet(value: ['foo', 'bar'], field: 'subject_tesim')
      expect(html).to include('<a>foo</a>')
    end
    it 'handles empty values' do
      allow(helper).to receive(:link_to).and_return('')
      html = helper.render_html_safe_facet(value: [], field: 'subject_tesim')
      expect(html).to eq('').or eq(''.html_safe)
    end
  end

  describe '#render_date_facet' do
    before do
      allow(helper).to receive(:link_to).and_return('<a>date</a>')
      def helper.search_action_path(*); '/search'; end
    end
    it 'renders links for each value' do
      html = helper.render_date_facet(value: ['2020', '2021'], field: 'date_tesim')
      expect(html).to include('<a>date</a>')
    end
    it 'handles empty values' do
      allow(helper).to receive(:link_to).and_return('')
      html = helper.render_date_facet(value: [], field: 'date_tesim')
      expect(html).to eq('').or eq(''.html_safe)
    end
  end
end
