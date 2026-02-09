require 'rails_helper'

RSpec.describe DownloadAndSetThumbsJob, type: :job do
  let(:record_id) { 'test-record-id' }
  let(:acda_record) { build(:acda, dc_type: 'Image', preview: 'http://example.com/preview.jpg') }

  before do
    allow(Acda).to receive(:where).and_return([acda_record])
  end

  describe '#perform' do
    context 'when record exists' do
      it 'finds the record' do
        expect(Acda).to receive(:where).with(id: record_id).and_return([acda_record])

        DownloadAndSetThumbsJob.perform_now(record_id)
      end
    end

    context 'when record does not exist' do
      before do
        allow(Acda).to receive(:where).and_return([])
      end

      it 'returns early' do
        DownloadAndSetThumbsJob.perform_now(record_id)
      end
    end

    context 'when record has no dc_type' do
      let(:acda_record) { build(:acda, dc_type: nil) }

      it 'resets queued job' do
        expect_any_instance_of(DownloadAndSetThumbsJob).to receive(:reset_queued_job).with(acda_record)

        DownloadAndSetThumbsJob.perform_now(record_id)
      end
    end

    context 'when record is audio/video' do
      let(:acda_record) { build(:acda, dc_type: 'Sound') }

      it 'resets queued job' do
        expect_any_instance_of(DownloadAndSetThumbsJob).to receive(:reset_queued_job).with(acda_record)

        DownloadAndSetThumbsJob.perform_now(record_id)
      end
    end

    context 'when record has no preview' do
      let(:acda_record) { build(:acda, dc_type: 'Image', preview: nil) }

      it 'unsets image and thumbnail' do
        expect_any_instance_of(DownloadAndSetThumbsJob).to receive(:unset_image_and_thumbnail!).with(acda_record)

        DownloadAndSetThumbsJob.perform_now(record_id)
      end
    end
  end

  describe 'retry_on error handling' do
    let(:error) { StandardError.new('Download failed') }

    it 'queues GenerateThumbsJob on retry exhaustion' do
      allow(Acda).to receive(:where).and_return([acda_record])
      expect(GenerateThumbsJob).to receive(:perform_later).with(acda_record.id)

      # Simulate the retry_on callback
      job = DownloadAndSetThumbsJob.new
      job.arguments = [record_id]
      DownloadAndSetThumbsJob.retry_on(StandardError).last.call(job, error)
    end
  end

  describe 'queue' do
    it 'is queued as import' do
      expect(DownloadAndSetThumbsJob.queue_name).to eq('import')
    end
  end
end