require 'rails_helper'

RSpec.describe DownloadDlgImageJob, type: :job do
  let(:record_id) { 'test-record-id' }
  let(:acda_record) { build(:acda, available_at: 'https://example.com', identifier: 'test-identifier') }

  before do
    allow(Acda).to receive(:where).and_return([acda_record])
    stub_request(:get, "https://dlg.usg.edu/images/iiif/2/dlg%2Fgych%2Frbrl001%2Ftest-identifier%2Ftest-identifier-00001.jp2/full/max/0/default.jpg").to_return(body: 'fake image data')
    stub_request(:get, 'https://example.com/thumbnail.jpg').to_return(body: 'fake image data')
  end

  describe '#perform' do
    context 'when record exists' do
      it 'finds the record' do
        expect(Acda).to receive(:where).with(id: record_id).and_return([acda_record])

        DownloadDlgImageJob.perform_now(record_id)
      end
    end

    context 'when record does not exist' do
      before do
        allow(Acda).to receive(:where).and_return([])
      end

      it 'returns early' do
        DownloadDlgImageJob.perform_now(record_id)
      end
    end

    context 'when record has no available_at' do
      let(:acda_record) { build(:acda, available_at: nil) }

      it 'resets queued job' do
        expect_any_instance_of(DownloadDlgImageJob).to receive(:reset_queued_job).with(acda_record)

        DownloadDlgImageJob.perform_now(record_id)
      end
    end
  end

  describe 'queue' do
    it 'is queued as import' do
      expect(DownloadDlgImageJob.queue_name).to eq('import')
    end
  end
end