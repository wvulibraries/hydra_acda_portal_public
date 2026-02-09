require 'rails_helper'

RSpec.describe GeneratePdfThumbsJob, type: :job do
  let(:record_id) { 'test-record-id' }
  let(:download_path) { '/tmp/test.pdf' }
  let(:acda_record) { build(:acda) }

  before do
    allow_any_instance_of(GeneratePdfThumbsJob).to receive(:valid_for_processing?).and_return(true)
    allow_any_instance_of(GeneratePdfThumbsJob).to receive(:find_record).and_return(acda_record)
    allow_any_instance_of(GeneratePdfThumbsJob).to receive(:process_pdf)
    allow_any_instance_of(GeneratePdfThumbsJob).to receive(:cleanup_files)
  end

  describe '#perform' do
    it 'validates processing requirements' do
      expect_any_instance_of(GeneratePdfThumbsJob).to receive(:valid_for_processing?).with(record_id, download_path)

      GeneratePdfThumbsJob.perform_now(record_id, download_path)
    end

    it 'finds the record' do
      expect_any_instance_of(GeneratePdfThumbsJob).to receive(:find_record).with(record_id)

      GeneratePdfThumbsJob.perform_now(record_id, download_path)
    end

    it 'processes the PDF' do
      expect_any_instance_of(GeneratePdfThumbsJob).to receive(:process_pdf).with(record_id, download_path, acda_record)

      GeneratePdfThumbsJob.perform_now(record_id, download_path)
    end

    it 'cleans up files' do
      expect_any_instance_of(GeneratePdfThumbsJob).to receive(:cleanup_files).with(record_id, download_path)

      GeneratePdfThumbsJob.perform_now(record_id, download_path)
    end

    context 'when validation fails' do
      before do
        allow_any_instance_of(GeneratePdfThumbsJob).to receive(:valid_for_processing?).and_return(false)
      end

      it 'returns early' do
        expect_any_instance_of(GeneratePdfThumbsJob).not_to receive(:find_record)

        GeneratePdfThumbsJob.perform_now(record_id, download_path)
      end
    end

    context 'when record not found' do
      before do
        allow_any_instance_of(GeneratePdfThumbsJob).to receive(:find_record).and_return(nil)
      end

      it 'returns early' do
        expect_any_instance_of(GeneratePdfThumbsJob).not_to receive(:process_pdf)

        GeneratePdfThumbsJob.perform_now(record_id, download_path)
      end
    end
  end

  describe 'queue' do
    it 'is queued as import' do
      expect(GeneratePdfThumbsJob.queue_name).to eq('import')
    end
  end
end