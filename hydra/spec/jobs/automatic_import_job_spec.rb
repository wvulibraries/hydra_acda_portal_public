require 'rails_helper'

RSpec.describe AutomaticImportJob, type: :job do
  let(:control_file) do
    {
      "project_name" => "test_project",
      "time_stamp" => Time.now.to_i.to_s,
      "contact_emails" => ["test@example.com"],
      "digital_items_count" => 5,
      "record_count" => 10
    }
  end
  let(:job) { described_class.new }
  let(:import_double) { double(run: true) }
  let(:control_dir) { "/mnt/nfs-exports/mfcs-exports/#{control_file['project_name']}/control/mfcs" }
  let(:process_dir) { "/mnt/nfs-exports/mfcs-exports/#{control_file['project_name']}/control/hydra/in-progress" }
  let(:finished_dir) { "/mnt/nfs-exports/mfcs-exports/#{control_file['project_name']}/control/hydra/finished" }
  let(:failed_dir) { "/mnt/nfs-exports/mfcs-exports/#{control_file['project_name']}/control/hydra/failed" }
  let(:yaml_file) { "#{control_file['time_stamp']}.yaml" }

  before do
    allow(AutomaticImport).to receive(:new).and_return(import_double)
    allow(Rails).to receive_message_chain(:env, :production?).and_return(false)
    allow(ImportMailer).to receive_message_chain(:email, :deliver_now)
    allow_any_instance_of(Object).to receive(:puts)
    allow_any_instance_of(Object).to receive(:sleep)
  end

  describe '#perform' do
    it 'runs the import job successfully' do
      allow(File).to receive(:rename)
      expect(AutomaticImport).to receive(:new).with(control_file).and_return(import_double)
      expect(import_double).to receive(:run)
      expect { job.perform(control_file) }.not_to raise_error
    end

    it 'retries up to 5 times and then aborts on failure' do
      failing_import = double(run: nil)
      allow(AutomaticImport).to receive(:new).and_return(failing_import)
      call_count = 0
      allow(failing_import).to receive(:run) do
        call_count += 1
        raise "fail"
      end
      allow(File).to receive(:rename).with("#{control_dir}/#{yaml_file}", "#{process_dir}/#{yaml_file}")
      expect(File).to receive(:rename).with("#{process_dir}/#{yaml_file}", "#{failed_dir}/#{yaml_file}")
      expect {
        job.perform(control_file)
      }.to raise_error(SystemExit)
      expect(call_count).to eq(5)
    end

    it 'sends failure email in production on repeated failure' do
      allow(Rails).to receive_message_chain(:env, :production?).and_return(true)
      failing_import = double(run: nil)
      allow(AutomaticImport).to receive(:new).and_return(failing_import)
      allow(failing_import).to receive(:run).and_raise("fail")
      allow(File).to receive(:rename).with("#{control_dir}/#{yaml_file}", "#{process_dir}/#{yaml_file}")
      expect(File).to receive(:rename).with("#{process_dir}/#{yaml_file}", "#{failed_dir}/#{yaml_file}")
      expect(ImportMailer).to receive_message_chain(:email, :deliver_now)
      expect {
        job.perform(control_file)
      }.to raise_error(SystemExit)
    end
  end
end
