require 'rails_helper'

RSpec.describe AutomaticImportJob, type: :job do
  let(:control_file) do
    {
      'project_name' => 'test_project',
      'time_stamp' => '1640995200', # 2022-01-01 00:00:00 UTC
      'contact_emails' => ['test@example.com'],
      'digital_items_count' => 10,
      'record_count' => 5
    }
  end

  let(:control_dir) { "/mnt/nfs-exports/mfcs-exports/test_project/control/mfcs" }
  let(:process_dir) { "/mnt/nfs-exports/mfcs-exports/test_project/control/hydra/in-progress" }
  let(:finished_dir) { "/mnt/nfs-exports/mfcs-exports/test_project/control/hydra/finished" }

  describe 'before_perform callback' do
    context 'in production environment' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        allow(ImportMailer).to receive_message_chain(:email, :deliver_now)
        allow(File).to receive(:rename)
        allow(AutomaticImport).to receive(:new).and_return(double(run: nil))
      end

      it 'sends notification email' do
        expect(ImportMailer).to receive(:email).with(
          ['test@example.com'],
          "Queueing Automatic Import for Test_project",
          a_string_including("The export for test_project was made on")
        ).and_return(double(deliver_now: true))

        AutomaticImportJob.perform_now(control_file)
      end

      it 'moves control file to in-progress directory' do
        expect(File).to receive(:rename).with(
          "#{control_dir}/1640995200.yaml",
          "#{process_dir}/1640995200.yaml"
        )

        AutomaticImportJob.perform_now(control_file)
      end
    end

    context 'in development environment' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
        allow(File).to receive(:rename)
        allow(AutomaticImport).to receive(:new).and_return(double(run: nil))
      end

      it 'does not send notification email' do
        expect(ImportMailer).not_to receive(:email)

        AutomaticImportJob.perform_now(control_file)
      end

      it 'still moves control file to in-progress directory' do
        expect(File).to receive(:rename).with(
          "#{control_dir}/1640995200.yaml",
          "#{process_dir}/1640995200.yaml"
        )

        AutomaticImportJob.perform_now(control_file)
      end
    end
  end

  describe 'after_perform callback' do
    before do
      allow(File).to receive(:rename)
      allow(AutomaticImport).to receive(:new).and_return(double(run: nil))
    end

    it 'moves control file to finished directory' do
      expect(File).to receive(:rename).with(
        "#{process_dir}/1640995200.yaml",
        "#{finished_dir}/1640995200.yaml"
      )

      AutomaticImportJob.perform_now(control_file)
    end
  end

  describe '#perform' do
    it 'executes without error' do
      # Mock the AutomaticImport class and File operations to prevent complex logic
      allow(AutomaticImport).to receive(:new).and_return(double(run: nil))
      allow(File).to receive(:rename)

      expect {
        AutomaticImportJob.perform_now(control_file)
      }.not_to raise_error
    end
  end

  describe 'queue' do
    it 'is queued as default' do
      expect(AutomaticImportJob.queue_name).to eq('default')
    end
  end
end