require 'rails_helper'

RSpec.describe Indexer do
  let(:image_file)     { double('image_file', present?: true, blank?: false) }
  let(:thumbnail_file) { double('thumbnail_file', present?: false, blank?: true) }
  let(:object) do
    double('Acda',
      image_file: image_file,
      thumbnail_file: thumbnail_file
    )
  end
  let(:indexer) { described_class.new(object) }

  describe '#generate_solr_document' do
    let(:base_doc) { { 'edtf_ssi' => '1995', 'title_tesim' => ['Test'] } }

    before do
      # Stub the parent class call to avoid Fedora dependency
      allow_any_instance_of(ActiveFedora::IndexingService).to receive(:generate_solr_document).and_return(base_doc)
    end

    it 'sets has_image_file_bsi to true when image_file is present' do
      result = indexer.generate_solr_document
      expect(result['has_image_file_bsi']).to be true
    end

    it 'sets has_thumbnail_file_bsi to false when thumbnail_file is not present' do
      result = indexer.generate_solr_document
      expect(result['has_thumbnail_file_bsi']).to be false
    end

    it 'adds date_ssim when edtf date is parseable' do
      result = indexer.generate_solr_document
      expect(result['date_ssim']).to eq(1995)
    end

    it 'does not add date_ssim when edtf is not parseable' do
      base_doc['edtf_ssi'] = 'not-a-date'
      result = indexer.generate_solr_document
      expect(result['date_ssim']).to be_nil
    end

    it 'does not add date_ssim when edtf_ssi is missing' do
      base_doc.delete('edtf_ssi')
      result = indexer.generate_solr_document
      expect(result['date_ssim']).to be_nil
    end
  end

  describe '#add_date (private)' do
    it 'returns a single year for a simple EDTF date' do
      result = indexer.send(:add_date, { 'edtf_ssi' => '1995' })
      expect(result).to eq(1995)
    end

    it 'returns an array of years for a date interval' do
      result = indexer.send(:add_date, { 'edtf_ssi' => '1990/1992' })
      expect(result).to eq([1990, 1991, 1992])
    end

    it 'returns a single-element array for an interval within the same year' do
      result = indexer.send(:add_date, { 'edtf_ssi' => '1995-01/1995-12' })
      expect(result).to eq([1995])
    end
  end
end
