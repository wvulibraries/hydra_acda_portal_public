require 'rails_helper'

RSpec.describe ImportRecordJob, type: :job do
  let(:export_path) { '/tmp/export' }
  let(:record) { { 'idno' => 'TEST.123', 'title' => 'Test Record' } }
  let(:processed_id) { 'TEST123' }

  describe '#perform' do
    context 'when record does not exist' do
      before do
        allow(Acda).to receive(:where).and_return([])
        allow(ImportLibrary).to receive(:modify_record).and_return(record)
        allow(ImportLibrary).to receive(:import_record)
      end

      it 'processes the record ID by removing dots' do
        expect(Acda).to receive(:where).with(identifier: processed_id)

        ImportRecordJob.perform_now(export_path, record)
      end

      it 'calls ImportLibrary.import_record with modified record' do
        expect(ImportLibrary).to receive(:modify_record).with(export_path, record)
        expect(ImportLibrary).to receive(:import_record).with(processed_id, record)

        ImportRecordJob.perform_now(export_path, record)
      end
    end

    context 'when record already exists' do
      let(:existing_record) { build(:acda) }

      before do
        allow(Acda).to receive(:where).and_return([existing_record])
      end

      it 'does not import the record' do
        expect(ImportLibrary).not_to receive(:import_record)

        ImportRecordJob.perform_now(export_path, record)
      end
    end
  end

  describe 'queue' do
    it 'is queued as default' do
      expect(ImportRecordJob.queue_name).to eq('default')
    end
  end
end