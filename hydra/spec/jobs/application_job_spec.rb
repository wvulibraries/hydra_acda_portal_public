# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationJob, type: :job do
  let(:job_class) do
    Class.new(ApplicationJob) do
      def self.name
        'TestJob'
      end

      def perform(id)
        # test job
      end
    end
  end

  let(:record_id) { 'test-record-123' }

  describe '.already_queued?' do
    context 'when GoodJob is being used' do
      it 'returns false when no matching job exists' do
        expect(job_class.already_queued?(record_id)).to eq(false)
      end

      it 'returns true if matching job is in queue' do
        allow(GoodJob::Job).to receive(:where).and_call_original
        fake_relation = double('relation')
        allow(fake_relation).to receive(:where).and_return(fake_relation)
        allow(fake_relation).to receive(:exists?).and_return(true)
        allow(GoodJob::Job).to receive(:where).with(
          "serialized_params->>'job_class' = ?", 'TestJob'
        ).and_return(fake_relation)

        expect(job_class.already_queued?(record_id)).to eq(true)
      end

      it 'returns true if matching job is pending (not finished)' do
        allow(GoodJob::Job).to receive(:where).and_call_original
        fake_relation = double('relation')
        allow(fake_relation).to receive(:where).and_return(fake_relation)
        allow(fake_relation).to receive(:exists?).and_return(true)
        allow(GoodJob::Job).to receive(:where).with(
          "serialized_params->>'job_class' = ?", 'TestJob'
        ).and_return(fake_relation)

        expect(job_class.already_queued?(record_id)).to eq(true)
      end

      it 'returns false if matching job is already finished' do
        allow(GoodJob::Job).to receive(:where).and_call_original
        fake_relation = double('relation')
        allow(fake_relation).to receive(:where).and_return(fake_relation)
        allow(fake_relation).to receive(:exists?).and_return(false)
        allow(GoodJob::Job).to receive(:where).with(
          "serialized_params->>'job_class' = ?", 'TestJob'
        ).and_return(fake_relation)

        expect(job_class.already_queued?(record_id)).to eq(false)
      end

      it 'returns false if job_class mismatches even if ID matches' do
        fake_relation = double('relation')
        allow(GoodJob::Job).to receive(:where).and_return(fake_relation)
        allow(fake_relation).to receive(:where).and_return(fake_relation)
        allow(fake_relation).to receive(:exists?).and_return(false)

        expect(job_class.already_queued?(record_id)).to eq(false)
      end
    end
  end

  describe '.perform_once' do
    it 'enqueues the job if not already queued' do
      allow(job_class).to receive(:already_queued?).with(record_id).and_return(false)
      expect(job_class).to receive(:perform_later).with(record_id)
      job_class.perform_once(record_id)
    end

    it 'does not enqueue if already queued' do
      allow(job_class).to receive(:already_queued?).with(record_id).and_return(true)
      expect(job_class).not_to receive(:perform_later)
      job_class.perform_once(record_id)
    end
  end
end
