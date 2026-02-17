require 'rails_helper'

RSpec.describe GenerateImageThumbsJob, type: :job do
  let(:record_id) { 'test-record-id' }
  let(:download_path) { '/tmp/test_image.jpg' }
  let(:acda_record) { build(:acda) }

  before do
    allow(File).to receive(:exist?).and_return(true)
    allow(Acda).to receive(:where).and_return([acda_record])
    allow(File).to receive(:rename).and_return(true)
    allow(File).to receive(:open).and_return(StringIO.new('fake file content'))
    allow(acda_record).to receive(:files).and_return(double('files', build: double('file'), present?: false))
    allow(acda_record).to receive(:build_image_file).and_return(double('file', save!: true, :mime_type= => nil, :content= => nil, :original_name= => nil))
    allow(acda_record).to receive(:build_thumbnail_file).and_return(double('file', save!: true, :mime_type= => nil, :content= => nil, :original_name= => nil))
    allow(acda_record).to receive(:save!)
    stub_request(:get, 'https://example.com/thumbnail.jpg').to_return(body: 'fake image data')
  end

  describe '#perform' do
    context 'when download file exists' do
      it 'checks if file exists' do
        expect(File).to receive(:exist?).with(download_path).and_return(true)

        GenerateImageThumbsJob.perform_now(record_id, download_path)
      end

      it 'finds the record' do
        expect(Acda).to receive(:where).with(id: record_id).and_return([acda_record])

        GenerateImageThumbsJob.perform_now(record_id, download_path)
      end
    end

    context 'when download file does not exist' do
      before do
        allow(File).to receive(:exist?).with(download_path).and_return(false)
      end

      it 'returns early' do
        GenerateImageThumbsJob.perform_now(record_id, download_path)
      end
    end

    context 'when record does not exist' do
      before do
        allow(Acda).to receive(:where).and_return([])
      end

      it 'returns early' do
        GenerateImageThumbsJob.perform_now(record_id, download_path)
      end
    end
  end

  describe 'queue' do
    it 'is queued as import' do
      expect(GenerateImageThumbsJob.queue_name).to eq('import')
    end
  end
end