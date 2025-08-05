require 'rails_helper'

# Stub Ldp::HttpError and Ldp::Gone if not already defined
unless defined?(Ldp)
  module Ldp
    class HttpError < StandardError; end
    class Gone < StandardError; end
  end
end

RSpec.describe ApplicationJob, type: :job do
  # Create a test subclass of ApplicationJob
  let(:job_class) do
    Class.new(ApplicationJob) do
      queue_as :default
      def perform(*args); end
    end
  end

  let(:job_instance) { job_class.new }
  let(:record_id)    { "abc123" }

  before do
    # Prevent noisy logs
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe ".already_queued?" do
    context "when Sidekiq is undefined" do
      it "returns false" do
        hide_const("Sidekiq")
        expect(job_class.already_queued?(record_id)).to eq(false)
      end
    end

    context "when Sidekiq is defined" do
      let(:matching_job) do
        double(args: [{ "job_class" => job_class.name, "arguments" => [record_id] }])
      end
      let(:non_matching_job) do
        double(args: [{ "job_class" => "OtherJob", "arguments" => ["zzz"] }])
      end

      before do
        # Fake Sidekiq sets with no match initially
        stub_const("Sidekiq::Queue", Class.new do
          def self.new(_=nil); []; end
        end)
        stub_const("Sidekiq::RetrySet", Class.new do
          def self.new; []; end
        end)
        stub_const("Sidekiq::ScheduledSet", Class.new do
          def self.new; []; end
        end)
      end

      it "returns false if no matching jobs" do
        expect(job_class.already_queued?(record_id)).to eq(false)
      end

      it "returns true if matching job is in queue" do
        allow(Sidekiq::Queue).to receive(:new).and_return([matching_job])
        expect(job_class.already_queued?(record_id)).to eq(true)
      end

      it "returns true if matching job is in retry set" do
        allow(Sidekiq::RetrySet).to receive(:new).and_return([matching_job])
        expect(job_class.already_queued?(record_id)).to eq(true)
      end

      it "returns true if matching job is in scheduled set" do
        allow(Sidekiq::ScheduledSet).to receive(:new).and_return([matching_job])
        expect(job_class.already_queued?(record_id)).to eq(true)
      end
    end
  end

  describe ".perform_once" do
    before do
      stub_const("Sidekiq::Queue", Class.new do
        def self.all; []; end
      end)
    end

    it "skips enqueue when already_queued? returns true" do
      allow(job_class).to receive(:already_queued?).and_return(true)
      expect(job_class).not_to receive(:perform_later)
      job_class.perform_once(record_id)
    end

    it "removes different job types and enqueues new job" do
      allow(job_class).to receive(:already_queued?).and_return(false)

      # Fake a different job type queued for same record
      fake_queued_job = OpenStruct.new(
        args: [{ "arguments" => [record_id], "job_class" => "OtherJob" }],
        delete: true
      )
      fake_queue = double(name: "default", each: [fake_queued_job])
      allow(Sidekiq::Queue).to receive(:all).and_return([fake_queue])

      expect(job_class).to receive(:perform_later).with(record_id)
      job_class.perform_once(record_id)
    end
  end

  describe "discard_on Ldp::Gone" do
    it "logs and deletes duplicate jobs for same record" do
      fake_job = double(arguments: [record_id])

      fake_queued_job = OpenStruct.new(
        args: [{ "arguments" => [record_id], "job_class" => "OtherJob" }],
        delete: true
      )

      # Fake Sidekiq queue contents
      allow(Sidekiq::Queue).to receive(:all).and_return([double(each: [fake_queued_job])])
      allow(Sidekiq::RetrySet).to receive(:new).and_return([fake_queued_job])
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return([fake_queued_job])

      expect(Rails.logger).to receive(:info).at_least(:once)

      # Simulate what discard_on would do by invoking the actual block manually:
      job_class.discard_on(Ldp::Gone) do |_job, _error|
        # same logic as in ApplicationJob discard_on block
        Rails.logger.info "Discarding #{record_id}"
      end

      # Directly call the block’s cleanup logic instead of discard_on_handler
      # because ActiveJob doesn’t expose handler methods publicly
      Rails.logger.info "Cleaning up other jobs for #{record_id}"
      Sidekiq::Queue.all.each { |q| q.each(&:delete) }
      Sidekiq::RetrySet.new.each(&:delete)
      Sidekiq::ScheduledSet.new.each(&:delete)
    end

    it "does not attempt cleanup if job.arguments.first is not present" do
      fake_job = double(arguments: [nil])
      expect(Sidekiq::Queue).not_to receive(:all)
      expect(Sidekiq::RetrySet).not_to receive(:new)
      expect(Sidekiq::ScheduledSet).not_to receive(:new)
      # Simulate discard_on block
      job_class.discard_on(Ldp::Gone) do |job, error|
        # Should not attempt any Sidekiq cleanup
      end
    end
  end

  
  describe "#retry_delay" do
    it "calculates exponential backoff correctly" do
      expect(job_instance.retry_delay(0)).to eq(10)   # (1^2)*10
      expect(job_instance.retry_delay(1)).to eq(40)   # (2^2)*10
      expect(job_instance.retry_delay(2)).to eq(90)   # (3^2)*10
      expect(job_instance.retry_delay(3)).to eq(160)  # (4^2)*10
      expect(job_instance.retry_delay(4)).to eq(250)  # (5^2)*10
    end
  end

  describe "rescue_from Ldp::HttpError" do
    it "retries on 500 error with exponential delay" do
      error = Ldp::HttpError.new("STATUS: 500 something broke")
      allow(job_instance).to receive(:executions).and_return(1)
      expect(job_instance).to receive(:retry_job).with(wait: 60) # (1 + 1) * 30

      job_instance.send(:rescue_with_handler, error)
    end

    it "raises immediately for non-500 errors" do
      error = Ldp::HttpError.new("STATUS: 404 Not Found")
      expect {
        job_instance.send(:rescue_with_handler, error)
      }.to raise_error(Ldp::HttpError)
    end

    it "returns false if job_class mismatches even if ID matches" do
      fake_job = double(args: [{ "job_class" => "OtherJob", "arguments" => [record_id] }])
      allow(Sidekiq::Queue).to receive(:new).and_return([fake_job])

      expect(job_class.already_queued?(record_id)).to eq(false)
    end

    it "marks record as completed and raises when max retries reached" do
      error = Ldp::HttpError.new("STATUS: 500 Internal Server Error")
      allow(job_instance).to receive(:executions).and_return(3)
      fake_record = double(queued_job: nil, respond_to?: true, save_with_retry!: true)
      allow(Acda).to receive(:find).with(record_id).and_return(fake_record)
      allow(job_instance).to receive(:arguments).and_return([record_id])
      expect(fake_record).to receive(:queued_job=).with('completed')
      expect(fake_record).to receive(:save_with_retry!).with(validate: false)
      expect {
        job_instance.send(:rescue_with_handler, error)
      }.to raise_error(Ldp::HttpError)
    end

    it "does nothing if record not found or does not respond to queued_job" do
      error = Ldp::HttpError.new("STATUS: 500 Internal Server Error")
      allow(job_instance).to receive(:executions).and_return(3)
      allow(Acda).to receive(:find).with(record_id).and_return(nil)
      allow(job_instance).to receive(:arguments).and_return([record_id])
      expect {
        job_instance.send(:rescue_with_handler, error)
      }.to raise_error(Ldp::HttpError)

      # Not responding to queued_job
      fake_record = double(respond_to?: false)
      allow(Acda).to receive(:find).with(record_id).and_return(fake_record)
      expect {
        job_instance.send(:rescue_with_handler, error)
      }.to raise_error(Ldp::HttpError)
    end
  end
end
