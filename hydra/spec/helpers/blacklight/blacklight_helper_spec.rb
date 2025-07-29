require 'rails_helper'

RSpec.describe BlacklightHelper, type: :helper do
  describe '#application_name' do
    it 'returns the portal name' do
      expect(helper.application_name).to eq('American Congress Digital Archives Portal')
    end
  end

  describe '#extract_year' do
    it 'extracts year from YYYY-MM-DD' do
      expect(helper.extract_year('2020-05-12')).to eq(2020)
    end
    it 'extracts year from YYYY-MM' do
      expect(helper.extract_year('1999-12')).to eq(1999)
    end
    it 'extracts year from YYYY' do
      expect(helper.extract_year('1987')).to eq(1987)
    end
    it 'returns input if not a date' do
      expect(helper.extract_year('not-a-date')).to eq('not-a-date')
    end
  end

  describe '#export_params' do
    let(:params) { { foo: 'bar' } }
    before { allow(helper).to receive(:params).and_return(params) }

    it 'returns params if no bookmarks' do
      allow(helper.controller).to receive(:instance_variable_get).with(:@bookmarks).and_return(nil)
      expect(helper.export_params).to eq(params)
    end

    it 'returns merged params if bookmarks present' do
      bookmarks = [double('Bookmark', document_id: 'doc1'), double('Bookmark', document_id: 'doc2')]
      allow(helper.controller).to receive(:instance_variable_get).with(:@bookmarks).and_return(bookmarks)
      allow(SolrDocument).to receive(:find).with('doc1').and_return({ 'identifier_ssi' => 'id1' })
      allow(SolrDocument).to receive(:find).with('doc2').and_return({ 'identifier_ssi' => 'id2' })
      result = helper.export_params
      expect(result['search_field']).to eq('identifier')
      expect(result['q']).to include('"id1"')
      expect(result['q']).to include('"id2"')
    end
  end
end
