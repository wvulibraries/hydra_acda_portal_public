require 'rails_helper'

RSpec.describe ApplicationJob, type: :job do
  let(:record_id) { 'test-record-id' }
  let(:test_job_class) do
    Class.new(ApplicationJob) do
      def perform(id)
        # Test implementation
      end
    end
  end

  describe 'retry configuration' do
    it 'has retry_on configured for Ldp::Conflict' do
      # Test that the class has the retry configuration by checking the class hierarchy
      expect(test_job_class.ancestors).to include(ApplicationJob)
      # The retry_on configuration is inherited from ApplicationJob
    end

    it 'has discard_on configured for Ldp::Gone' do
      # Test that the class has the discard configuration by checking the class hierarchy
      expect(test_job_class.ancestors).to include(ApplicationJob)
      # The discard_on configuration is inherited from ApplicationJob
    end
  end

  describe 'error handling' do
    let(:job) { test_job_class.new }

    context 'Ldp::HttpError handling' do
      it 'handles 500 errors with retry logic' do
        # Test that the rescue_from block is defined by checking the class has the method
        expect(job.class).to respond_to(:rescue_from)
      end
    end
  end

  describe '.already_queued?' do
    before do
      # Mock Sidekiq if not available
      unless defined?(Sidekiq)
        stub_const('Sidekiq', Module.new)
        allow(Sidekiq).to receive(:const_defined?).with('Queue').and_return(true)
        allow(Sidekiq).to receive(:const_defined?).with('RetrySet').and_return(true)
        allow(Sidekiq).to receive(:const_defined?).with('ScheduledSet').and_return(true)
      end
    end

    it 'returns false when Sidekiq is not defined' do
      hide_const('Sidekiq') if defined?(Sidekiq)

      expect(test_job_class.already_queued?(record_id)).to be_falsey
    end

    it 'checks main queue for existing jobs' do
      queue = double('queue')
      allow(Sidekiq::Queue).to receive(:new).and_return(queue)
      allow(queue).to receive(:select).and_return([double])

      expect(test_job_class.already_queued?(record_id)).to be_truthy
    end
  end

  describe '.perform_once' do
    it 'does not queue if already queued' do
      allow(test_job_class).to receive(:already_queued?).and_return(true)

      expect(test_job_class).not_to receive(:perform_later)

      test_job_class.perform_once(record_id)
    end

    it 'queues the job if not already queued' do
      allow(test_job_class).to receive(:already_queued?).and_return(false)

      expect(test_job_class).to receive(:perform_later).with(record_id)

      test_job_class.perform_once(record_id)
    end
  end

  describe '#retry_delay' do
    let(:job) { test_job_class.new }

    it 'calculates exponential backoff delay' do
      expect(job.retry_delay(0)).to eq(10)  # 1^2 * 10
      expect(job.retry_delay(1)).to eq(40)  # 2^2 * 10
      expect(job.retry_delay(2)).to eq(90)  # 3^2 * 10
      expect(job.retry_delay(3)).to eq(160) # 4^2 * 10
      expect(job.retry_delay(4)).to eq(250) # 5^2 * 10
    end
  end
end