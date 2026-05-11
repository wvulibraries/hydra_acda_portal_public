require 'rails_helper'

RSpec.describe GenerateImageThumbsJob, type: :job do
  let(:id) { 'abc123' }
  let(:download_path) { '/tmp/test.jpg' }
  let(:image_path) { "/home/hydra/tmp/images/#{id}.jpg" }
  let(:thumbnail_path) { "/home/hydra/tmp/thumbnails/#{id}.jpg" }
  let(:files_assoc) { double('files_assoc', present?: false, build: nil) }
  let(:record) do
    double(
      id: id,
      files: files_assoc,
      build_image_file: double,
      build_thumbnail_file: double,
      save_with_retry!: true
    ).tap do |rec|
      allow(rec).to receive(:queued_job)
      allow(rec).to receive(:queued_job=)
    end
  end
  let(:logger) { double(info: nil, error: nil) }

  before do
    allow(Acda).to receive(:where).and_return([record])
    allow(File).to receive(:exist?).and_return(true)
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:mv)
    allow(File).to receive(:delete)
    allow(Dir).to receive(:glob).and_return([])
    allow(ImportLibrary).to receive(:set_file)
    allow(Logger).to receive(:new).and_return(logger)
    allow_any_instance_of(Object).to receive(:puts)
  end

  describe '#perform' do
    it 'returns unless download_path exists' do
      allow(File).to receive(:exist?).with(download_path).and_return(false)
      expect(Acda).not_to receive(:where)
      expect(described_class.new.perform(id, download_path)).to be_nil
    end

    it 'returns unless record is found' do
      allow(Acda).to receive(:where).and_return([])
      expect(described_class.new.perform(id, download_path)).to be_nil
    end

    it 'sets up logging, moves file, builds files, and sets image/thumbnail' do
      job = described_class.new
      allow(File).to receive(:exist?).with(image_path).and_return(true)
      allow(File).to receive(:exist?).with(thumbnail_path).and_return(true)
      expect(FileUtils).to receive(:mv).with(download_path, image_path)
      expect(record.files).to receive(:present?).and_return(false)
      expect(record.files).to receive(:build)
      expect(ImportLibrary).to receive(:set_file).with(record.build_image_file, 'application/jpg', image_path)
      expect(ImportLibrary).to receive(:set_file).with(record.build_thumbnail_file, 'application/jpg', thumbnail_path)
      expect(record).to receive(:queued_job=).with('completed')
      expect(record).to receive(:save_with_retry!).with(validate: false)
      job.perform(id, download_path)
    end

    it 'marks record as error and raises if exception occurs' do
      job = described_class.new
      allow(FileUtils).to receive(:mv).and_raise(StandardError, 'fail')
      expect(record).to receive(:queued_job=).with('error')
      expect(record).to receive(:save_with_retry!).with(validate: false)
      expect { job.perform(id, download_path) }.to raise_error(StandardError)
    end

    it 'cleans up files after successful save' do
      job = described_class.new
      allow(File).to receive(:exist?).with(image_path).and_return(true)
      allow(File).to receive(:exist?).with(thumbnail_path).and_return(true)
      expect(File).to receive(:delete).with(image_path)
      expect(Dir).to receive(:glob).with(/#{id}\*/).and_return([image_path, thumbnail_path])
      expect(File).to receive(:delete).with(image_path)
      expect(File).to receive(:delete).with(thumbnail_path)
      job.perform(id, download_path)
    end
  end
end
