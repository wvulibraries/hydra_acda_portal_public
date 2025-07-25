require 'rails_helper'

RSpec.describe GeneratePdfThumbsJob, type: :job do
  let(:id) { 'abc123' }
  let(:download_path) { '/tmp/test.pdf' }
  let(:files_assoc) { double('files_assoc', present?: false, build: nil) }
  let(:record) do
    double(
      id: id,
      files: files_assoc,
      build_image_file: double,
      build_thumbnail_file: double,
      save!: true
    ).tap do |rec|
      allow(rec).to receive(:queued_job)
      allow(rec).to receive(:queued_job=)
    end
  end

  before do
    allow(Acda).to receive(:where).and_return([record])
    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:size).and_return(100)
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:cp)
    allow(Dir).to receive(:glob).and_return([])
    allow(File).to receive(:delete)
    allow(Rails.logger).to receive(:error)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
    allow(ImportLibrary).to receive(:set_file)
    allow_any_instance_of(Object).to receive(:puts)
  end

  describe '#perform' do
    it 'returns unless id or download_path is missing' do
      expect_any_instance_of(described_class).not_to receive(:find_record)
      expect(described_class.new.perform(nil, download_path)).to be_nil
      expect(described_class.new.perform(id, nil)).to be_nil
    end

    it 'returns unless file does not exist or is empty' do
      allow(File).to receive(:exist?).and_return(false)
      expect_any_instance_of(described_class).not_to receive(:find_record)
      expect(described_class.new.perform(id, download_path)).to be_nil
    end

    it 'returns unless record is found' do
      allow(Acda).to receive(:where).and_return([])
      expect(Rails.logger).to receive(:error).with(/Record not found/)
      expect(described_class.new.perform(id, download_path)).to be_nil
    end

    it 'calls process_pdf and cleanup_files on success' do
      job = described_class.new
      expect(job).to receive(:process_pdf).with(id, download_path, record).and_call_original
      expect(job).to receive(:cleanup_files).with(id, download_path).and_call_original
      allow(job).to receive(:process_images) # prevent MiniMagick call
      allow(MiniMagick::Tool::Convert).to receive(:new)
      job.perform(id, download_path)
    end

    it 'logs and raises error if process_pdf fails' do
      job = described_class.new
      allow(job).to receive(:process_pdf).and_raise(StandardError, 'fail')
      expect(Rails.logger).to receive(:error).with(/Failed to process PDF/)
      expect { job.perform(id, download_path) }.to raise_error(StandardError)
    end
  end

  describe '#process_pdf' do
    it 'creates pdf dir, copies file, builds files, and calls process_images' do
      job = described_class.new
      expect(FileUtils).to receive(:mkdir_p).with('/home/hydra/tmp/pdf')
      expect(FileUtils).to receive(:cp).with(download_path, "/home/hydra/tmp/pdf/#{id}.pdf")
      expect(record.files).to receive(:present?).and_return(false)
      expect(record.files).to receive(:build)
      expect(job).to receive(:process_images).with(id, "/home/hydra/tmp/pdf/#{id}.pdf", record)
      job.send(:process_pdf, id, download_path, record)
    end
  end

  describe '#process_images' do
    let(:job) { described_class.new }
    it 'calls convert_pdf_to_image, find_image_path, and create_thumbnail' do
      allow(job).to receive(:setup_image_path).and_return('/home/hydra/tmp/images')
      expect(job).to receive(:convert_pdf_to_image)
      expect(job).to receive(:find_image_path).and_return('/home/hydra/tmp/images/abc123.jpg')
      expect(record).to receive(:build_image_file).and_return(double)
      expect(ImportLibrary).to receive(:set_file)
      expect(record).to receive(:save!)
      expect(job).to receive(:create_thumbnail)
      job.send(:process_images, id, '/home/hydra/tmp/pdf/abc123.pdf', record)
    end
  end

  

  describe '#find_image_path' do
    it 'returns correct path if file exists' do
      allow(File).to receive(:exist?).with('/tmp/images/abc123.jpg').and_return(true)
      expect(described_class.new.send(:find_image_path, 'abc123', '/tmp/images')).to eq('/tmp/images/abc123.jpg')
    end
    it 'returns -0 path if -0 file exists' do
      allow(File).to receive(:exist?).with('/tmp/images/abc123.jpg').and_return(false)
      allow(File).to receive(:exist?).with('/tmp/images/abc123-0.jpg').and_return(true)
      expect(described_class.new.send(:find_image_path, 'abc123', '/tmp/images')).to eq('/tmp/images/abc123-0.jpg')
    end
    it 'returns nil and logs error if no file exists' do
      allow(File).to receive(:exist?).and_return(false)
      expect(Rails.logger).to receive(:error).with(/No image generated/)
      expect(described_class.new.send(:find_image_path, 'abc123', '/tmp/images')).to be_nil
    end
  end

  describe '#create_thumbnail' do
    it 'creates thumbnail and sets file if successful' do
      job = described_class.new
      allow(FileUtils).to receive(:mkdir_p)
      allow(MiniMagick::Tool::Convert).to receive(:new)
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:size).and_return(100)
      expect(ImportLibrary).to receive(:set_file)
      expect(record).to receive(:build_thumbnail_file)
      expect(record).to receive(:queued_job=).with('false')
      expect(record).to receive(:save!)
      expect(job.send(:create_thumbnail, id, '/tmp/images/abc123.jpg', record)).to eq(true)
    end
    it 'logs error and returns false if thumbnail not created' do
      job = described_class.new
      allow(FileUtils).to receive(:mkdir_p)
      allow(MiniMagick::Tool::Convert).to receive(:new)
      allow(File).to receive(:exist?).and_return(false)
      expect(Rails.logger).to receive(:error).with(/Failed to create thumbnail/)
      expect(job.send(:create_thumbnail, id, '/tmp/images/abc123.jpg', record)).to eq(false)
    end
    it 'logs error and returns false on exception' do
      job = described_class.new
      allow(FileUtils).to receive(:mkdir_p)
      allow(MiniMagick::Tool::Convert).to receive(:new).and_raise(StandardError, 'fail')
      expect(Rails.logger).to receive(:error).with(/Error in create_thumbnail/)
      expect(job.send(:create_thumbnail, id, '/tmp/images/abc123.jpg', record)).to eq(false)
    end
  end

  describe '#cleanup_files' do
    it 'removes files if they exist' do
      job = described_class.new
      allow(File).to receive(:exist?).and_return(true)
      expect(File).to receive(:delete).at_least(:once)
      job.send(:cleanup_files, id, download_path)
    end
  end
end
