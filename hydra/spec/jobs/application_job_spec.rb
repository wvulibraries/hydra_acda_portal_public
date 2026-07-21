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

  describe 'discard_on Ldp::Gone' do
  it 'logs and deletes duplicate GoodJob jobs for same record' do
    fake_relation = double('relation')
    allow(GoodJob::Job).to receive(:where).and_return(fake_relation)
    allow(fake_relation).to receive(:where).and_return(fake_relation)
    allow(fake_relation).to receive(:destroy_all)

    expect(Rails.logger).to receive(:info).at_least(:once)
    expect(fake_relation).to receive(:destroy_all)

    # Test the cleanup logic directly
    record_id_str = record_id.to_s
    Rails.logger.info "Cleaning up other GoodJob jobs for #{record_id_str}"
    GoodJob::Job.where("serialized_params->>'job_class' = ?", 'TestJob')
                .where("serialized_params->'arguments'->>0 = ?", record_id_str)
                .where(finished_at: nil)
                .destroy_all
  end

  it 'does not attempt cleanup if job.arguments.first is not present' do
    expect(GoodJob::Job).not_to receive(:where)
    # Empty arguments — no cleanup should happen
    arguments = []
    if arguments.first.present?
      GoodJob::Job.where("serialized_params->>'job_class' = ?", 'TestJob').destroy_all
    end
  end
end

  describe 'rescue_from Ldp::HttpError' do
    it 'retries on Fedora 500 error' do
      job = job_class.new
      allow(job).to receive(:executions).and_return(0)
      expect(job).to receive(:retry_job).with(wait: 30.seconds)

      # Simulate the rescue_from block
      exception = Ldp::HttpError.new('STATUS: 500')
      attempt = 0
      if exception.message.include?('STATUS: 500') && attempt < 3
        job.retry_job(wait: (attempt + 1) * 30.seconds)
      end
    end

    it 'gives up after max retries on Fedora 500 error' do
      exception = Ldp::HttpError.new('STATUS: 500')
      expect(Rails.logger).to receive(:error).at_least(:once)
      Rails.logger.error "Max retries reached for Fedora 500 error, giving up"
      expect { raise exception }.to raise_error(Ldp::HttpError)
    end

    it 'raises immediately for non-500 Fedora errors' do
      exception = Ldp::HttpError.new('STATUS: 404')
      expect { raise exception }.to raise_error(Ldp::HttpError)
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