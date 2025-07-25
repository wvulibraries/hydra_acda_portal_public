require 'rails_helper'

RSpec.describe GenerateThumbsJob, type: :job do
  let(:record) do
    double(
      id: 'abc123',
      dc_type: 'Image',
      available_by: 'https://example.com/file.jpg',
      available_at: nil,
      queued_job: nil,
      save_with_retry!: true
    )
  end
  let(:logger) { Logger.new(nil) }
  let(:job) { described_class.new }

  before do
    allow(Acda).to receive(:where).and_return([record])
    allow(Rails.logger).to receive(:error)
    allow(Rails.logger).to receive(:info)
    allow(FileUtils).to receive(:mkdir_p)
    allow(File).to receive(:exist?).and_return(false)
    allow(Logger).to receive(:new).and_return(logger)
    allow(record).to receive(:save_with_retry!)
  end

  describe '#perform' do
    it 'logs and returns if record not found' do
      allow(Acda).to receive(:where).and_return([])
      expect(Rails.logger).to receive(:error).with(/not found/)
      expect { job.perform('missing') }.not_to raise_error
    end

    it 'handles video records and marks as completed on success' do
      allow(record).to receive(:dc_type).and_return('MovingImage')
      allow(job).to receive(:handle_video_thumbnail).and_return(true)
      expect(record).to receive(:queued_job=).with('completed')
      expect(record).to receive(:save_with_retry!).with(validate: false)
      job.perform(record.id)
    end

    it 'creates default video thumbnail if video thumbnail fails' do
      allow(record).to receive(:dc_type).and_return('MovingImage')
      allow(job).to receive(:handle_video_thumbnail).and_return(false)
      expect(job).to receive(:create_default_video_thumbnail)
      expect(record).to receive(:queued_job=).with('completed')
      expect(record).to receive(:save_with_retry!).with(validate: false)
      job.perform(record.id)
    end

    it 'skips unsupported types and marks as completed' do
      allow(record).to receive(:dc_type).and_return('Sound')
      expect(record).to receive(:queued_job=).with('completed')
      expect(record).to receive(:save_with_retry!).with(validate: false)
      job.perform(record.id)
    end

    it 'downloads and handles file if available_by present' do
      allow(record).to receive(:available_by).and_return('https://example.com/file.jpg')
      allow(job).to receive(:process_url).and_return(true)
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:size).and_return(100)
      expect(job).to receive(:handle_downloaded_file)
      job.perform(record.id)
    end

    it 'marks as completed if download fails' do
      allow(record).to receive(:available_by).and_return('https://example.com/file.jpg')
      allow(job).to receive(:process_url).and_return(false)
      expect(record).to receive(:queued_job=).with('completed')
      expect(record).to receive(:save_with_retry!).with(validate: false)
      job.perform(record.id)
    end

    it 'rescues and marks as completed on error' do
      allow(record).to receive(:available_by).and_raise(StandardError, 'fail')
      expect(record).to receive(:queued_job=).with('completed')
      expect(record).to receive(:save_with_retry!).with(validate: false)
      expect { job.perform(record.id) }.to raise_error(StandardError)
    end
  end

  describe '#process_url' do
    it 'calls download_resource for direct file' do
      expect(job).to receive(:direct_file?).and_return(true)
      expect(job).to receive(:download_resource).and_return(true)
      job.send(:process_url, 'http://file.pdf', '/tmp/file', logger)
    end

    it 'calls extract_and_download_embedded_file for non-direct file' do
      expect(job).to receive(:direct_file?).and_return(false)
      expect(job).to receive(:extract_and_download_embedded_file).and_return(true)
      job.send(:process_url, 'http://webpage', '/tmp/file', logger)
    end
  end

  describe '#direct_file?' do
    it 'returns true for supported file extension' do
      expect(job.send(:direct_file?, 'http://foo.com/file.pdf')).to eq(true)
      expect(job.send(:direct_file?, 'http://foo.com/file.JPG')).to eq(true)
    end
    it 'returns false for nil' do
      expect(job.send(:direct_file?, nil)).to eq(false)
    end
    it 'returns true for /download/ path' do
      expect(job.send(:direct_file?, 'http://foo.com/download/')).to eq(true)
    end
    it 'returns false for unsupported url' do
      expect(job.send(:direct_file?, 'http://foo.com/file.txt')).to eq(false)
    end
  end

  describe '#extract_vimeo_id' do
    it 'extracts id from vimeo.com url' do
      expect(job.send(:extract_vimeo_id, 'https://vimeo.com/12345')).to eq('12345')
      expect(job.send(:extract_vimeo_id, 'https://player.vimeo.com/video/67890')).to eq('67890')
      expect(job.send(:extract_vimeo_id, 'https://example.com')).to be_nil
    end
  end

  describe '#extract_youtube_id' do
    it 'extracts id from youtube urls' do
      expect(job.send(:extract_youtube_id, 'https://youtube.com/watch?v=abc123')).to eq('abc123')
      expect(job.send(:extract_youtube_id, 'https://youtu.be/xyz789')).to eq('xyz789')
      expect(job.send(:extract_youtube_id, 'https://youtube.com/embed/abc')).to eq('abc')
      expect(job.send(:extract_youtube_id, 'https://youtube.com/v/def')).to eq('def')
      expect(job.send(:extract_youtube_id, 'https://example.com')).to be_nil
    end
  end
end
