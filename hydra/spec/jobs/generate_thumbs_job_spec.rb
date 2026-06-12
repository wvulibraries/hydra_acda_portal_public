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

    it 'marks as completed if both available_by and available_at are nil' do
      allow(record).to receive(:available_by).and_return(nil)
      allow(record).to receive(:available_at).and_return(nil)
      expect(record).to receive(:queued_job=).with('completed')
      expect(record).to receive(:save_with_retry!).with(validate: false)
      job.perform(record.id)
    end

    it 'marks as completed if process_url returns true but file does not exist' do
      allow(record).to receive(:available_by).and_return('https://example.com/file.jpg')
      allow(job).to receive(:process_url).and_return(true)
      allow(File).to receive(:exist?).and_return(false)
      expect(record).to receive(:queued_job=).with('completed')
      expect(record).to receive(:save_with_retry!).with(validate: false)
      job.perform(record.id)
    end

    it 'marks as completed if process_url returns true but file is empty' do
      allow(record).to receive(:available_by).and_return('https://example.com/file.jpg')
      allow(job).to receive(:process_url).and_return(true)
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:size).and_return(0)
      expect(record).to receive(:queued_job=).with('completed')
      expect(record).to receive(:save_with_retry!).with(validate: false)
      job.perform(record.id)
    end

    it 'logs info for unsupported type and marks as completed' do
      allow(record).to receive(:dc_type).and_return(nil)
      expect(logger).to receive(:info).with(/Skipping unsupported type/)
      expect(record).to receive(:queued_job=).with('completed')
      expect(record).to receive(:save_with_retry!).with(validate: false)
      job.perform(record.id)
    end

    it 'logs error if no file was downloaded' do
      allow(record).to receive(:available_by).and_return('https://example.com/file.jpg')
      allow(job).to receive(:process_url).and_return(false)
      allow(record).to receive(:queued_job=)
      allow(record).to receive(:save_with_retry!)
      allow(logger).to receive(:error)
      expect(logger).to receive(:error).with(a_string_matching('No file was successfully downloaded'))
      job.perform(record.id)
    end

    it 'logs error and re-raises in rescue block' do
      allow(record).to receive(:available_by).and_raise(StandardError, 'fail')
      allow(record).to receive(:queued_job=)
      allow(record).to receive(:save_with_retry!)
      allow(logger).to receive(:error)
      expect(logger).to receive(:error).with(a_string_matching('Error in GenerateThumbsJob'))
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

  describe '#handle_video_thumbnail' do
    let(:record) { double(id: 'abc', available_by: 'https://vimeo.com/12345', available_at: nil) }
    let(:logger) { Logger.new(nil) }
    let(:job) { described_class.new }

    it 'returns false if no url' do
      rec = double(available_by: nil, available_at: nil)
      expect(job.send(:handle_video_thumbnail, rec, logger)).to eq(false)
    end

    it 'returns false if extract_vimeo_id returns nil' do
      allow(record).to receive(:available_by).and_return('https://vimeo.com/')
      expect(job.send(:handle_video_thumbnail, record, logger)).to eq(false)
    end

    it 'returns false if download_resource fails for vimeo' do
      allow(record).to receive(:available_by).and_return('https://vimeo.com/12345')
      allow(job).to receive(:extract_vimeo_id).and_return('12345')
      allow(URI).to receive(:open).and_return(StringIO.new('{"thumbnail_url":"http://thumb"}'))
      allow(JSON).to receive(:parse).and_return({ 'thumbnail_url' => 'http://thumb' })
      allow(job).to receive(:download_resource).and_return(false)
      expect(job.send(:handle_video_thumbnail, record, logger)).to eq(false)
    end

    it 'rescues and returns false for vimeo error' do
      allow(record).to receive(:available_by).and_return('https://vimeo.com/12345')
      allow(job).to receive(:extract_vimeo_id).and_return('12345')
      allow(URI).to receive(:open).and_raise(StandardError.new('fail'))
      expect(logger).to receive(:error).with(/Error processing Vimeo thumbnail/)
      expect(job.send(:handle_video_thumbnail, record, logger)).to eq(false)
    end

    it 'returns false if extract_youtube_id returns nil' do
      rec = double(id: 'abc', available_by: 'https://youtube.com/', available_at: nil)
      expect(job.send(:handle_video_thumbnail, rec, logger)).to eq(false)
    end

    it 'returns false if all youtube thumbnails fail' do
      rec = double(id: 'abc', available_by: 'https://youtube.com/watch?v=abc', available_at: nil)
      allow(job).to receive(:extract_youtube_id).and_return('abc')
      allow(job).to receive(:download_resource).and_return(false)
      expect(logger).to receive(:error).with(/Failed to download any YouTube thumbnails/)
      expect(job.send(:handle_video_thumbnail, rec, logger)).to eq(false)
    end

    it 'returns false for unknown video url' do
      rec = double(id: 'abc', available_by: 'https://notavideo.com/', available_at: nil)
      expect(logger).to receive(:info).with(/Unable to extract thumbnail/)
      expect(job.send(:handle_video_thumbnail, rec, logger)).to eq(false)
    end

    it 'logs and returns true for successful Vimeo thumbnail' do
      allow(record).to receive(:available_by).and_return('https://vimeo.com/12345')
      allow(job).to receive(:extract_vimeo_id).and_return('12345')
      allow(URI).to receive(:open).and_return(StringIO.new('{"thumbnail_url":"http://thumb"}'))
      allow(JSON).to receive(:parse).and_return({ 'thumbnail_url' => 'http://thumb' })
      allow(job).to receive(:download_resource).and_return(true)
      allow(File).to receive(:size).and_return(2000)
      allow(logger).to receive(:info)
      expect(logger).to receive(:info).with(a_string_matching('Found Vimeo thumbnail'))
      expect(GenerateImageThumbsJob).to receive(:perform_later).with(record.id, anything)
      expect(job.send(:handle_video_thumbnail, record, logger)).to eq(true)
    end

    it 'logs and returns true for successful YouTube thumbnail' do
      rec = double(id: 'abc', available_by: 'https://youtube.com/watch?v=abc', available_at: nil)
      allow(job).to receive(:extract_youtube_id).and_return('abc')
      allow(job).to receive(:download_resource).and_return(false, false, true)
      allow(File).to receive(:size).and_return(2001)
      allow(logger).to receive(:info)
      expect(logger).to receive(:info).with(a_string_matching('Successfully downloaded YouTube thumbnail'))
      expect(GenerateImageThumbsJob).to receive(:perform_later).with(rec.id, anything)
      expect(job.send(:handle_video_thumbnail, rec, logger)).to eq(true)
    end
  end

  describe '#create_default_video_thumbnail' do
    let(:record) { double(id: 'abc', title: 'Test', queued_job: nil, save_with_retry!: true) }
    let(:logger) { instance_spy(Logger) }
    let(:job) { described_class.new }

    it 'rescues and marks as completed on MiniMagick error' do
      allow(MiniMagick::Image).to receive(:new).and_raise(StandardError.new('fail'))
      expect(logger).to receive(:error).with(/Failed to create default thumbnail/)
      expect(record).to receive(:queued_job=).with('completed')
      expect(record).to receive(:save_with_retry!).with(validate: false)
      expect(job.send(:create_default_video_thumbnail, record, '/tmp/path', logger)).to eq(false)
    end

    
  end

  describe '#handle_downloaded_file' do
    let(:record) { double(id: 'abc123') }
    let(:logger) { Logger.new(nil) }

    it 'calls GeneratePdfThumbsJob for PDF files' do
      allow(Open3).to receive(:capture2).and_return(['application/pdf', nil])
      allow_any_instance_of(GenerateThumbsJob).to receive(:`).and_return('application/pdf')
      expect(GeneratePdfThumbsJob).to receive(:perform_later).with(record.id, anything)
      described_class.new.send(:handle_downloaded_file, record, '/tmp/file.pdf', logger)
    end

    it 'calls GenerateImageThumbsJob for image files' do
      allow_any_instance_of(GenerateThumbsJob).to receive(:`).and_return('image/png')
      expect(GenerateImageThumbsJob).to receive(:perform_later).with(record.id, anything)
      described_class.new.send(:handle_downloaded_file, record, '/tmp/file.png', logger)
    end

    it 'does nothing for unsupported mime type' do
      allow_any_instance_of(GenerateThumbsJob).to receive(:`).and_return('application/zip')
      expect(GeneratePdfThumbsJob).not_to receive(:perform_later)
      expect(GenerateImageThumbsJob).not_to receive(:perform_later)
      described_class.new.send(:handle_downloaded_file, record, '/tmp/file.zip', logger)
    end
  end

  describe '#download_resource' do
    let(:logger) { Logger.new(nil) }

    it 'downloads and writes binary file' do
      url = 'https://example.com/image.jpg'
      path = '/tmp/image.jpg'
      fake_data = 'FAKE_BINARY_DATA'

      allow(URI).to receive(:open).with(url).and_return(StringIO.new(fake_data))
      expect(File).to receive(:open).with(path, 'wb')
      described_class.new.send(:download_resource, url, path, logger)
    end

    it 'logs error and returns false on failure' do
      allow(URI).to receive(:open).and_raise(StandardError.new("fail"))
      expect(logger).to receive(:error).with(/fail/)
      result = job.send(:download_resource, "http://bad-url.com", "/tmp/file", logger)
      expect(result).to eq(false)
    end
  end

  describe '#extract_and_download_embedded_file' do
    let(:logger) { Logger.new(nil) }
    let(:html) { '<html><body><a class="new-primary" href="/download/file/sample.pdf">Download</a></body></html>' }

    it 'extracts embedded file and downloads it' do
      url = 'https://example.com/page'
      allow(URI).to receive(:open).with(url).and_return(StringIO.new(html))
      allow_any_instance_of(GenerateThumbsJob).to receive(:download_resource).and_return(true)
      expect_any_instance_of(GenerateThumbsJob).to receive(:download_resource).with('https://example.com/download/file/sample.pdf', anything, logger)
      described_class.new.send(:extract_and_download_embedded_file, url, '/tmp/sample.pdf', logger)
    end

    it 'downloads embedded file when link is found' do
      html = '<html><body><a class="new-primary" href="/download/file/sample.pdf">Download</a></body></html>'
      allow(URI).to receive(:open).and_return(StringIO.new(html))
      expect(job).to receive(:download_resource).with("http://example.com/download/file/sample.pdf", "/tmp/path", logger).and_return(true)
      result = job.send(:extract_and_download_embedded_file, "http://example.com/page", "/tmp/path", logger)
      expect(result).to be true
    end

    it 'returns false when no download link is found' do
      html = '<html><body><p>No links here</p></body></html>'
      allow(URI).to receive(:open).and_return(StringIO.new(html))
      result = job.send(:extract_and_download_embedded_file, "http://example.com/page", "/tmp/path", logger)
      expect(result).to be false
    end

    it 'rescues and logs error if fetching or parsing fails' do
      allow(URI).to receive(:open).and_raise(StandardError.new('fail'))
      expect(logger).to receive(:error).with(/Error extracting embedded file/)
      result = job.send(:extract_and_download_embedded_file, 'http://bad-url.com', '/tmp/path', logger)
      expect(result).to eq(false)
    end
  end

  describe '#handle_dlg_record' do
    let(:logger) { instance_spy(Logger) }
    let(:record) { double(id: 'abc', dc_type: nil, save!: true) }
    let(:job) { described_class.new }

    before do
      allow(Acda).to receive(:where).with(id: 'abc').and_return([record])
    end

    it 'rescues and logs error if processing fails' do
      allow(URI).to receive(:open).and_raise(StandardError.new('fail'))
      expect(logger).to receive(:error).with(/Failed to process DLG record/)
      job.send(:handle_dlg_record, 'http://bad-url.com', '/tmp/path', logger)
    end

  
  end

  it 'uses available_at when available_by is nil' do
    allow(record).to receive(:available_by).and_return(nil)
    allow(record).to receive(:available_at).and_return('https://example.com/file.png')

    expect(job).to receive(:process_url).with('https://example.com/file.png', anything, logger).and_return(false)
    expect(record).to receive(:queued_job=).with('completed')
    expect(record).to receive(:save_with_retry!).with(validate: false)

    job.perform(record.id)
  end

end
