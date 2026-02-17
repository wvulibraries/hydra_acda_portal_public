require 'rails_helper'

RSpec.describe ProcessThumbnailJob, type: :job do
  let(:record_id) { 'test-record-id' }
  let(:acda_record) { build(:acda, dc_type: 'Image') }

  before do
    allow(Acda).to receive(:with_thumbnail_lock).and_yield(acda_record)
    stub_request(:get, 'https://example.com/thumbnail.jpg').to_return(body: 'fake image data')
  end

  describe '#perform' do
    it 'acquires thumbnail lock on the record' do
      expect(Acda).to receive(:with_thumbnail_lock).with(record_id).and_yield(acda_record)

      ProcessThumbnailJob.perform_now(record_id)
    end

    context 'with image type' do
      let(:acda_record) { build(:acda, dc_type: 'Image') }

      it 'processes image thumbnail' do
        allow_any_instance_of(ProcessThumbnailJob).to receive(:process_image_thumbnail)

        ProcessThumbnailJob.perform_now(record_id)
      end
    end

    context 'with video type' do
      let(:acda_record) { build(:acda, dc_type: 'MovingImage') }

      it 'processes video thumbnail' do
        allow_any_instance_of(ProcessThumbnailJob).to receive(:process_video_thumbnail)

        ProcessThumbnailJob.perform_now(record_id)
      end
    end

    context 'with preview present' do
      let(:acda_record) { build(:acda, dc_type: 'Text', preview: 'http://example.com/preview.jpg') }

      it 'processes preview thumbnail' do
        allow_any_instance_of(ProcessThumbnailJob).to receive(:process_preview_thumbnail)

        ProcessThumbnailJob.perform_now(record_id)
      end
    end

    context 'with PDF URL' do
      let(:acda_record) { build(:acda, available_by: 'http://example.com/download/file.pdf') }

      it 'processes PDF thumbnail' do
        allow_any_instance_of(ProcessThumbnailJob).to receive(:process_pdf_thumbnail)

        ProcessThumbnailJob.perform_now(record_id)
      end
    end
  end

  describe '.perform_once' do
    it 'queues the job if not already queued' do
      allow(ProcessThumbnailJob).to receive(:already_queued?).and_return(false)
      expect(ProcessThumbnailJob).to receive(:perform_later).with(record_id, 'arg1', 'arg2')

      ProcessThumbnailJob.perform_once(record_id, 'arg1', 'arg2')
    end

    it 'does not queue if already queued' do
      allow(ProcessThumbnailJob).to receive(:already_queued?).and_return(true)
      expect(ProcessThumbnailJob).not_to receive(:perform_later)

      ProcessThumbnailJob.perform_once(record_id)
    end
  end

  describe 'queue' do
    it 'is queued as import' do
      expect(ProcessThumbnailJob.queue_name).to eq('import')
    end
  end
end