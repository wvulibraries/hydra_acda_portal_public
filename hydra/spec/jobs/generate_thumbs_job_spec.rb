require 'rails_helper'

RSpec.describe GenerateThumbsJob, type: :job do
  let(:acda_record) { build(:acda, dc_type: 'Image') }
  let(:record_id) { 'test-id' }

  before do
    allow(Acda).to receive(:where).and_return([acda_record])
    allow(acda_record).to receive(:save_with_retry!)
  end

  describe '#perform' do
    context 'when record exists' do
      it 'finds the record' do
        expect(Acda).to receive(:where).with(id: record_id).and_return([acda_record])

        GenerateThumbsJob.perform_now(record_id)
      end

      it 'marks job as completed' do
        expect(acda_record).to receive(:queued_job=).with('completed')
        expect(acda_record).to receive(:save_with_retry!).with(validate: false)

        GenerateThumbsJob.perform_now(record_id)
      end
    end

    context 'when record does not exist' do
      before do
        allow(Acda).to receive(:where).and_return([])
      end

      it 'logs error and returns early' do
        expect(Rails.logger).to receive(:error).with("Record #{record_id} not found, marking job as completed")

        GenerateThumbsJob.perform_now(record_id)
      end
    end

    context 'when record is a video' do
      let(:acda_record) { build(:acda, dc_type: 'MovingImage') }

      it 'handles video thumbnail generation' do
        allow_any_instance_of(GenerateThumbsJob).to receive(:handle_video_thumbnail).and_return(true)

        GenerateThumbsJob.perform_now(record_id)
      end
    end

    context 'when record type is unsupported' do
      let(:acda_record) { build(:acda, dc_type: 'Sound') }

      it 'skips processing and marks as completed' do
        expect(acda_record).to receive(:queued_job=).with('completed')
        expect(acda_record).to receive(:save_with_retry!).with(validate: false)

        GenerateThumbsJob.perform_now(record_id)
      end
    end
  end

  describe 'queue' do
    it 'is queued as import' do
      expect(GenerateThumbsJob.queue_name).to eq('import')
    end
  end
end