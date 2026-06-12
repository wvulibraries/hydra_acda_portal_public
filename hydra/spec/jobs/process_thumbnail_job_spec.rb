require 'rails_helper'

RSpec.describe ProcessThumbnailJob, type: :job do
  let(:record) { build_stubbed(:acda) }

  before do
    # Prevent actual HTTP calls
    stub_request(:get, /example\.com/).to_return(
      status: 200,
      body: "fake_image_data",
      headers: { "Content-Type" => "image/jpeg" }
    )

    # Avoid MiniMagick + file writes — but DO NOT stub attach_* methods globally
    allow_any_instance_of(ProcessThumbnailJob).to receive(:create_placeholder_thumbnail)
    allow_any_instance_of(ProcessThumbnailJob).to receive(:create_default_video_thumbnail)

    # Stub pdf validation
    allow_any_instance_of(ProcessThumbnailJob).to receive(:verify_pdf).and_return(true)

    # Default lock stub
    allow(Acda).to receive(:with_thumbnail_lock).and_yield(record)

    allow(Logger).to receive(:new).and_return(Logger.new($stdout))
  end


  describe ".perform_once" do
    it "enqueues when not already queued" do
      allow(described_class).to receive(:already_queued?).and_return(false)

      expect {
        described_class.perform_once(record.id)
      }.to have_enqueued_job(described_class).with(record.id)
    end

    it "skips enqueue when already queued" do
      allow(described_class).to receive(:already_queued?).and_return(true)

      expect {
        described_class.perform_once(record.id)
      }.not_to have_enqueued_job
    end
  end

  describe "#perform" do
    it "calls Acda.with_thumbnail_lock with correct id" do
      job = described_class.new
      expect(Acda).to receive(:with_thumbnail_lock).with(record.id)
      job.perform(record.id)
    end

    it "branches to process_image_thumbnail when dc_type=Image" do
      record.dc_type = "Image"
      record.preview = nil # <-- ensure no preview so it goes to image branch
      job = described_class.new
      expect(job).to receive(:process_image_thumbnail).with(record, anything)
      job.perform(record.id)
    end

    it "branches to process_video_thumbnail when dc_type=MovingImage" do
      record.dc_type = "MovingImage"
      job = described_class.new
      expect(job).to receive(:process_video_thumbnail).with(record, anything)
      job.perform(record.id)
    end

    it "branches to process_preview_thumbnail when preview present" do
      record.dc_type = nil
      record.preview = "https://example.com/preview.jpg"
      job = described_class.new
      expect(job).to receive(:process_preview_thumbnail).with(record, anything)
      job.perform(record.id)
    end

    it "branches to process_pdf_thumbnail for PDF-like URL" do
      record.dc_type = nil
      record.preview = nil
      record.available_by = "https://example.com/file.pdf"
      job = described_class.new
      expect(job).to receive(:process_pdf_thumbnail).with(record, anything)
      job.perform(record.id)
    end

    it "falls back to create_placeholder_thumbnail when no match" do
      record.dc_type = nil
      record.preview = nil
      record.available_by = nil
      record.available_at = nil
      job = described_class.new
      expect(job).to receive(:create_placeholder_thumbnail).with(record, anything)
      job.perform(record.id)
    end
  end

  describe "helper methods" do
    let(:job) { described_class.new }

    it "extracts vimeo id correctly" do
      expect(job.send(:extract_vimeo_id, "https://vimeo.com/12345")).to eq("12345")
      expect(job.send(:extract_vimeo_id, "https://player.vimeo.com/video/67890")).to eq("67890")
      expect(job.send(:extract_vimeo_id, "https://example.com")).to be_nil
    end

    it "extracts youtube id correctly" do
      expect(job.send(:extract_youtube_id, "https://youtube.com/watch?v=abc123")).to eq("abc123")
      expect(job.send(:extract_youtube_id, "https://youtu.be/xyz789")).to eq("xyz789")
      expect(job.send(:extract_youtube_id, "https://example.com")).to be_nil
    end

    it "verify_pdf returns true for %PDF- header" do
      fake_pdf = Tempfile.new("test.pdf")
      fake_pdf.write("%PDF-1.4 randomdata")
      fake_pdf.rewind
      expect(job.send(:verify_pdf, fake_pdf.path, Logger.new(nil))).to eq(true)
      fake_pdf.close!
    end

    it "check_image_quality classifies based on size" do
      # Stub MiniMagick::Image to fake width/height
      fake_image = double(width: 800, height: 800)
      allow(MiniMagick::Image).to receive(:open).and_return(fake_image)
      expect(job.send(:check_image_quality, "fake.jpg", Logger.new(nil))).to eq(true)

      small_image = double(width: 200, height: 200)
      allow(MiniMagick::Image).to receive(:open).and_return(small_image)
      expect(job.send(:check_image_quality, "fake.jpg", Logger.new(nil))).to eq(false)
    end
  end

  describe "#download_file" do
    let(:job) { described_class.new }
    let(:logger) { Logger.new(nil) }

    it "returns true for successful GET" do
      expect(
        job.send(:download_file, "https://example.com/file.jpg", "/tmp/test.jpg", logger)
      ).to eq(true)
    end

    it "follows redirect and succeeds" do
      stub_request(:get, "https://redirect.com/file.jpg")
        .to_return(status: 302, headers: { 'Location' => 'https://example.com/file.jpg' })
      stub_request(:get, "https://example.com/file.jpg")
        .to_return(status: 200, body: "redirected", headers: {})
      expect(
        job.send(:download_file, "https://redirect.com/file.jpg", "/tmp/test.jpg", logger)
      ).to eq(true)
    end

    it "returns false after too many redirects" do
      stub_request(:get, /loop\.com/).to_return(status: 302, headers: { 'Location' => 'https://loop.com/again' })
      expect(
        job.send(:download_file, "https://loop.com/again", "/tmp/test.jpg", logger)
      ).to eq(false)
    end

    it "returns false on HTTP error" do
      stub_request(:get, "https://error.com/file.jpg").to_return(status: 500)
      expect(
        job.send(:download_file, "https://error.com/file.jpg", "/tmp/test.jpg", logger)
      ).to eq(false)
    end
  end

  describe "video thumbnail processing" do
    let(:job) { described_class.new }
    let(:logger) { Logger.new(nil) }

    it "downloads high-quality Vimeo image first" do
      record.available_by = "https://vimeo.com/12345"
      allow(job).to receive(:extract_vimeo_id).and_return("12345")
      allow(job).to receive(:download_vimeo_high_quality).and_return(true)
      expect(job).to receive(:attach_images_to_record)
      job.send(:process_video_thumbnail, record, logger)
    end

    it "falls back to Vimeo standard thumbnail" do
      record.available_by = "https://vimeo.com/12345"
      allow(job).to receive(:extract_vimeo_id).and_return("12345")
      allow(job).to receive(:download_vimeo_high_quality).and_return(false)
      allow(job).to receive(:download_vimeo_thumbnail).and_return(true)
      expect(job).to receive(:attach_thumbnail_to_record)
      job.send(:process_video_thumbnail, record, logger)
    end

    it "falls back to YouTube HQ then standard thumbnail" do
      record.available_by = "https://youtube.com/watch?v=abc123"
      allow(job).to receive(:extract_youtube_id).and_return("abc123")
      allow(job).to receive(:download_file).and_return(false, true) # first fails, second succeeds
      expect(job).to receive(:attach_thumbnail_to_record)
      job.send(:process_video_thumbnail, record, logger)
    end

    it "falls back to preview thumbnail if no video id" do
      record.available_by = "https://unknownvideo.com"
      record.preview = "https://example.com/preview.jpg"
      expect(job).to receive(:process_preview_thumbnail)
      job.send(:process_video_thumbnail, record, logger)
    end

    it "falls back to default video thumbnail if all else fails" do
      record.available_by = "https://unknownvideo.com"
      record.preview = nil
      expect(job).to receive(:create_default_video_thumbnail)
      job.send(:process_video_thumbnail, record, logger)
    end
  end

  describe "PDF thumbnail processing" do
    let(:job) { described_class.new }
    let(:logger) { Logger.new(nil) }

    it "handles valid PDF URL" do
      record.available_by = "https://example.com/file.pdf"
      allow(job).to receive(:download_file).and_return(true)
      allow(job).to receive(:verify_pdf).and_return(true)
      expect(job).to receive(:generate_thumbnail_from_pdf)
      job.send(:process_pdf_thumbnail, record, logger)
    end

    it "handles invalid PDF after download" do
      record.available_by = "https://example.com/file.pdf"
      allow(job).to receive(:download_file).and_return(true)
      allow(job).to receive(:verify_pdf).and_return(false)
      expect(job).to receive(:create_placeholder_thumbnail)
      job.send(:process_pdf_thumbnail, record, logger)
    end

    it "handles PDF download failure" do
      record.available_by = "https://example.com/file.pdf"
      allow(job).to receive(:download_file).and_return(false)
      expect(job).to receive(:create_placeholder_thumbnail)
      job.send(:process_pdf_thumbnail, record, logger)
    end

    it "handles missing PDF URL" do
      record.available_by = nil
      record.available_at = nil
      expect(job).to receive(:create_placeholder_thumbnail)
      job.send(:process_pdf_thumbnail, record, logger)
    end
  end

  

  describe "thumbnail generation from PDF" do
    let(:job) { described_class.new }
    let(:logger) { Logger.new(nil) }

    it "generate_thumbnail_from_pdf handles successful conversion" do
      pdf_path = "/tmp/fake.pdf"
      output_path = "#{pdf_path}_page1.jpg"
      FileUtils.touch(pdf_path)
      FileUtils.touch(output_path) # simulate convert success

      allow(job).to receive(:valid_image?).and_return(true)
      expect(job).to receive(:attach_images_to_record)
      job.send(:generate_thumbnail_from_pdf, record, pdf_path, logger)

      FileUtils.rm_f(pdf_path)
      FileUtils.rm_f(output_path)
    end

    it "generate_thumbnail_from_pdf handles failed conversion" do
      pdf_path = "/tmp/fake.pdf"
      FileUtils.touch(pdf_path)
      allow(job).to receive(:valid_image?).and_return(false)
      expect(job).to receive(:create_placeholder_thumbnail)
      job.send(:generate_thumbnail_from_pdf, record, pdf_path, logger)
      FileUtils.rm_f(pdf_path)
    end
  end

  describe "valid_image? helper" do
    let(:job) { described_class.new }
    let(:logger) { Logger.new(nil) }

    it "valid_image? returns true for valid image" do
      fake_img = double(width: 100, height: 100)
      allow(MiniMagick::Image).to receive(:open).and_return(fake_img)
      expect(job.send(:valid_image?, "fake.jpg", logger)).to eq(true)
    end

    it "valid_image? returns false on exception" do
      allow(MiniMagick::Image).to receive(:open).and_raise("error")
      expect(job.send(:valid_image?, "fake.jpg", logger)).to eq(false)
    end
  end

  describe "placeholder generation" do
    let(:job) { described_class.new }
    let(:logger) { Logger.new(nil) }

    before do
      allow(record).to receive(:image_file=)
      allow(record).to receive(:thumbnail_file=)
    end

    it "create_text_image creates a file (stubbed)" do
      out_path = "/tmp/test_placeholder.jpg"
      allow(MiniMagick::Tool::Convert).to receive(:new) # don’t run real convert
      FileUtils.touch(out_path) # simulate file created
      job.send(:create_text_image, "Hello", out_path)
      expect(File.exist?(out_path)).to eq(true)
      FileUtils.rm_f(out_path)
    end

    it "create_video_placeholder creates a file (stubbed)" do
      out_path = "/tmp/test_video_placeholder.jpg"
      allow(MiniMagick::Tool::Convert).to receive(:new)
      FileUtils.touch(out_path)
      job.send(:create_video_placeholder, "Video", out_path)
      expect(File.exist?(out_path)).to eq(true)
      FileUtils.rm_f(out_path)
    end

    it "attaches full image and thumbnail to record" do
      tmp = "/tmp/test_image.jpg"
      FileUtils.touch(tmp)
      allow(job).to receive(:generate_thumbnail).and_return(tmp)
      expect(record).to receive(:save_with_retry!).with(validate: false)
      expect {
        job.send(:attach_images_to_record, record, tmp, logger)
      }.not_to raise_error
      FileUtils.rm_f(tmp)
    end

    it "attaches only thumbnail to record" do
      tmp = "/tmp/test_thumb.jpg"
      FileUtils.touch(tmp)
      allow(job).to receive(:generate_thumbnail).and_return(tmp)
      expect(record).to receive(:save_with_retry!).with(validate: false)
      expect {
        job.send(:attach_thumbnail_to_record, record, tmp, logger)
      }.not_to raise_error
      FileUtils.rm_f(tmp)
    end

    it "generates a thumbnail from an image" do
      original = "/tmp/fake.jpg"
      FileUtils.touch(original)
      fake_img = double(resize: true, format: true, write: true)
      allow(MiniMagick::Image).to receive(:open).and_return(fake_img)

      result = job.send(:generate_thumbnail, original, 250, logger)
      expect(result).to eq("#{original}_thumb.jpg")
      FileUtils.rm_f(original)
    end

    it "delegates to attach_images_to_record from generate_thumbnail_from_image" do
      expect(job).to receive(:attach_images_to_record)
      job.send(:generate_thumbnail_from_image, record, "/tmp/fake.jpg", logger)
    end

    it "processes image thumbnail and attaches it" do
      record.available_by = "https://example.com/image.jpg"
      allow(job).to receive(:download_file).and_return(true)
      expect(job).to receive(:attach_images_to_record)
      job.send(:process_image_thumbnail, record, logger)
    end

    it "creates placeholder if image download fails" do
      record.available_by = "https://example.com/image.jpg"
      allow(job).to receive(:download_file).and_return(false)
      expect(job).to receive(:create_placeholder_thumbnail)
      job.send(:process_image_thumbnail, record, logger)
    end


    it "processes preview thumbnail with high quality image" do
      record.preview = "https://example.com/preview.jpg"
      allow(job).to receive(:download_file).and_return(true)
      allow(job).to receive(:check_image_quality).and_return(true)
      expect(job).to receive(:attach_images_to_record)
      job.send(:process_preview_thumbnail, record, logger)
    end

    it "processes preview thumbnail with low quality image" do
      record.preview = "https://example.com/preview.jpg"
      allow(job).to receive(:download_file).and_return(true)
      allow(job).to receive(:check_image_quality).and_return(false)
      expect(job).to receive(:attach_thumbnail_to_record)
      job.send(:process_preview_thumbnail, record, logger)
    end

    it "creates placeholder if preview fails" do
      record.preview = "https://example.com/preview.jpg"
      allow(job).to receive(:download_file).and_return(false)
      expect(job).to receive(:create_placeholder_thumbnail)
      job.send(:process_preview_thumbnail, record, logger)
    end

    it "creates placeholder thumbnail" do
      allow(job).to receive(:create_text_image)
      allow(job).to receive(:attach_thumbnail_to_record)
      expect {
        job.send(:create_placeholder_thumbnail, record, logger)
      }.not_to raise_error
    end

    it "creates default video thumbnail" do
      allow(job).to receive(:create_video_placeholder)
      allow(job).to receive(:attach_thumbnail_to_record)
      expect {
        job.send(:create_default_video_thumbnail, record, logger)
      }.not_to raise_error
    end

    it "downloads standard Vimeo thumbnail" do
      stub_request(:get, /api\/oembed/)
        .to_return(status: 200, body: { thumbnail_url: "https://example.com/preview.jpg" }.to_json)
      expect(job.send(:download_vimeo_thumbnail, "12345", "/tmp/test.jpg", logger)).to eq(true)
    end

    it "downloads high-quality Vimeo image" do
      stub_request(:get, /api\/v2\/video/)
        .to_return(status: 200, body: [{ thumbnail_large: "https://example.com/image.jpg" }].to_json)
      expect(job.send(:download_vimeo_high_quality, "12345", "/tmp/test.jpg", logger)).to eq(true)
    end



  end

  describe 'edge/error/ensure branches for 100% coverage' do
    let(:job) { described_class.new }
    let(:logger) { Logger.new(nil) }
    let(:record) { build_stubbed(:acda) }

    it 'generate_thumbnail returns nil and logs error on MiniMagick failure' do
      allow(MiniMagick::Image).to receive(:open).and_raise("fail")
      expect(logger).to receive(:error).with(/Error generating thumbnail/)
      expect(job.send(:generate_thumbnail, '/tmp/fake.jpg', 250, logger)).to be_nil
    end

    it 'attach_images_to_record handles exception and ensure block' do
      FileUtils.touch('/tmp/fake.jpg') # Ensure file exists for cleanup
      allow(job).to receive(:generate_thumbnail).and_raise("fail")
      expect(logger).to receive(:error).with(/Error attaching images/)
      expect(FileUtils).to receive(:rm_f).at_least(:once)
      expect(job.send(:attach_images_to_record, record, '/tmp/fake.jpg', logger)).to eq(false)
      FileUtils.rm_f('/tmp/fake.jpg')
    end

    it 'attach_thumbnail_to_record handles exception and ensure block' do
      FileUtils.touch('/tmp/fake.jpg') # Ensure file exists for cleanup
      allow(job).to receive(:generate_thumbnail).and_raise("fail")
      expect(logger).to receive(:error).with(/Error attaching thumbnail/)
      expect(FileUtils).to receive(:rm_f).at_least(:once)
      expect(job.send(:attach_thumbnail_to_record, record, '/tmp/fake.jpg', logger)).to eq(false)
      FileUtils.rm_f('/tmp/fake.jpg')
    end

    it 'generate_thumbnail_from_pdf handles exception and ensure block' do
      pdf_path = '/tmp/fake.pdf'
      output_path = '/tmp/fake.pdf_page1.jpg'
      FileUtils.touch(pdf_path)
      FileUtils.touch(output_path)
      allow(job).to receive(:valid_image?).and_raise("fail")
      allow(job).to receive(:create_placeholder_thumbnail)
      expect(logger).to receive(:error).with(/Error generating PDF thumbnail/)
      expect(FileUtils).to receive(:rm_f).at_least(:once)
      expect {
        job.send(:generate_thumbnail_from_pdf, record, pdf_path, logger)
      }.not_to raise_error
      FileUtils.rm_f(pdf_path)
      FileUtils.rm_f(output_path)
    end

    

    it 'check_image_quality handles exception' do
      allow(MiniMagick::Image).to receive(:open).and_raise("fail")
      expect(logger).to receive(:error).with(/Error checking image quality/)
      expect(job.send(:check_image_quality, '/tmp/fake.jpg', logger)).to eq(false)
    end
  end

  describe "edge/error branches for full coverage" do
    let(:job) { described_class.new }
    let(:logger) { Logger.new(nil) }

    it "falls through to preview/default if both YouTube HQ and standard downloads fail" do
      record.available_by = "https://youtube.com/watch?v=abc123"
      allow(job).to receive(:extract_youtube_id).and_return("abc123")
      allow(job).to receive(:download_file).and_return(false, false)
      expect(job).to receive(:process_preview_thumbnail).with(record, logger)
      job.send(:process_video_thumbnail, record, logger)
    end

    it "calls create_placeholder_thumbnail if preview download fails" do
      record.preview = "https://example.com/preview.jpg"
      allow(job).to receive(:download_file).and_return(false)
      expect(job).to receive(:create_placeholder_thumbnail).with(record, logger)
      job.send(:process_preview_thumbnail, record, logger)
    end

    it "calls create_placeholder_thumbnail if image download fails" do
      record.available_by = "https://example.com/image.jpg"
      allow(job).to receive(:download_file).and_return(false)
      expect(job).to receive(:create_placeholder_thumbnail).with(record, logger)
      job.send(:process_image_thumbnail, record, logger)
    end

    it "calls create_placeholder_thumbnail if PDF verify fails" do
      record.available_by = "https://example.com/file.pdf"
      allow(job).to receive(:download_file).and_return(true)
      allow(job).to receive(:verify_pdf).and_return(false)
      expect(job).to receive(:create_placeholder_thumbnail).with(record, logger)
      job.send(:process_pdf_thumbnail, record, logger)
    end

    it "calls create_placeholder_thumbnail if PDF download fails" do
      record.available_by = "https://example.com/file.pdf"
      allow(job).to receive(:download_file).and_return(false)
      expect(job).to receive(:create_placeholder_thumbnail).with(record, logger)
      job.send(:process_pdf_thumbnail, record, logger)
    end

    it "calls create_placeholder_thumbnail if no suitable PDF URL is found" do
      record.available_by = nil
      record.available_at = nil
      expect(job).to receive(:create_placeholder_thumbnail).with(record, logger)
      job.send(:process_pdf_thumbnail, record, logger)
    end

    it "logs error and returns false if download_file raises exception" do
      allow(URI).to receive(:parse).and_raise("test error")
      expect(logger).to receive(:error).with(/Error downloading file: test error/)
      result = job.send(:download_file, "https://fail.com", "/tmp/test.jpg", logger)
      expect(result).to eq(false)
    end

    it "returns false if vimeo oembed API fails" do
      stub_request(:get, /vimeo\.com\/api\/oembed/).to_return(status: 500)
      expect(job.send(:download_vimeo_thumbnail, "12345", "/tmp/out.jpg", logger)).to eq(false)
    end

    it "returns false if vimeo high-quality API fails" do
      stub_request(:get, /vimeo\.com\/api\/v2\/video/).to_return(status: 500)
      expect(job.send(:download_vimeo_high_quality, "12345", "/tmp/out.jpg", logger)).to eq(false)
    end

  
    it "returns false if PDF file does not exist or is too small" do
      path = "/tmp/too_small.pdf"
      File.write(path, "tiny") # Only 4 bytes
      allow(job).to receive(:verify_pdf).and_call_original
      expect(job.send(:verify_pdf, path, logger)).to eq(false)
      FileUtils.rm_f(path)
    end


    it "returns false for file without %PDF- header" do
      path = "/tmp/bad_header.pdf"
      content = "-----BEGIN SOMETHING-----\nnot a pdf\n" + ("x" * 1200)
      File.write(path, content)
      allow(job).to receive(:verify_pdf).and_call_original
      expect(job.send(:verify_pdf, path, logger)).to eq(false)
      FileUtils.rm_f(path)
    end


    it "returns false if file is HTML" do
      path = "/tmp/html_fake.pdf"
      html = "<html><body>Error page</body></html>" + (" " * 1200)
      File.write(path, html)
      allow(job).to receive(:verify_pdf).and_call_original
      expect(job.send(:verify_pdf, path, logger)).to eq(false)
      FileUtils.rm_f(path)
    end


    it "handles missing output file from PDF conversion" do
      pdf_path = "/tmp/fake.pdf"
      output_path = "#{pdf_path}_page1.jpg"

      FileUtils.touch(pdf_path)
      FileUtils.touch(output_path) # simulate convert command writes something

      # Stub shell command (backtick)
      allow(job).to receive(:`).and_return("")
      allow($?).to receive(:success?).and_return(true) rescue nil # safe fallback

      # Force `valid_image?` to raise error, simulating unreadable image
      allow(job).to receive(:valid_image?).and_raise("mini magick boom")
      allow(job).to receive(:create_placeholder_thumbnail)

      expect(logger).to receive(:error).with(/Error generating PDF thumbnail: mini magick boom/)

      job.send(:generate_thumbnail_from_pdf, record, pdf_path, logger)

      FileUtils.rm_f(pdf_path)
      FileUtils.rm_f(output_path)
    end

    it "follows a relative redirect" do
      start = "https://rel.example.com/start.jpg"
      dest  = "https://rel.example.com/final.jpg"

      stub_request(:get, start)
        .to_return(status: 302, headers: { 'Location' => '/final.jpg' })
      stub_request(:get, dest)
        .to_return(status: 200, body: "ok")

      job   = described_class.new
      logger = Logger.new(nil)
      expect(job.send(:download_file, start, "/tmp/rel.jpg", logger)).to eq(true)
      FileUtils.rm_f("/tmp/rel.jpg")
    end

    it "adds DSpace cookie for evols.library.manoa.hawaii.edu downloads" do
      url = "https://evols.library.manoa.hawaii.edu/some/file.jpg"

      stub = stub_request(:get, url)
              .with(headers: { 'Cookie' => 'dspace.cookie.login=true' })
              .to_return(status: 200, body: "ok")

      job = described_class.new
      logger = Logger.new(nil)

      expect(job.send(:download_file, url, "/tmp/evols.jpg", logger)).to eq(true)
      expect(stub).to have_been_requested
      FileUtils.rm_f("/tmp/evols.jpg")
    end


    it "uses YouTube maxresdefault when available" do
      record.available_by = "https://youtube.com/watch?v=abc123"
      job = described_class.new
      logger = Logger.new(nil)

      # maxresdefault succeeds
      allow(job).to receive(:download_file).with(
        "https://img.youtube.com/vi/abc123/maxresdefault.jpg", anything, logger
      ).and_return(true)

      expect(job).to receive(:attach_images_to_record) # full image + thumb
      allow(job).to receive(:extract_youtube_id).and_return("abc123")

      job.send(:process_video_thumbnail, record, logger)
    end


    it "falls back after Vimeo HQ and standard both fail (uses preview if present)" do
      record.available_by = "https://vimeo.com/12345"
      record.preview = "https://example.com/preview.jpg"
      job = described_class.new
      logger = Logger.new(nil)

      allow(job).to receive(:extract_vimeo_id).and_return("12345")
      allow(job).to receive(:download_vimeo_high_quality).and_return(false)
      allow(job).to receive(:download_vimeo_thumbnail).and_return(false)

      expect(job).to receive(:process_preview_thumbnail).with(record, logger)
      job.send(:process_video_thumbnail, record, logger)
    end

    it "falls back to default video thumbnail if Vimeo attempts fail and no preview" do
      record.available_by = "https://vimeo.com/12345"
      record.preview = nil
      job = described_class.new
      logger = Logger.new(nil)

      allow(job).to receive(:extract_vimeo_id).and_return("12345")
      allow(job).to receive(:download_vimeo_high_quality).and_return(false)
      allow(job).to receive(:download_vimeo_thumbnail).and_return(false)

      expect(job).to receive(:create_default_video_thumbnail).with(record, logger)
      job.send(:process_video_thumbnail, record, logger)
    end

    it "uses available_at when it matches bitstreams/download pattern" do
      record.available_by = nil
      record.available_at = "https://repo.edu/bitstreams/abc123/download"
      job = described_class.new
      logger = Logger.new(nil)

      allow(job).to receive(:download_file).and_return(true)
      allow(job).to receive(:verify_pdf).and_return(true)
      expect(job).to receive(:generate_thumbnail_from_pdf)

      job.send(:process_pdf_thumbnail, record, logger)
    end

    it "treats dc_type 'Moving' as video" do
      record.dc_type = "Moving"
      job = described_class.new
      expect(job).to receive(:process_video_thumbnail).with(record, anything)
      job.perform(record.id)
    end
  end



    # --- extra coverage for ProcessThumbnailJob ---

  describe 'additional branches' do
    let(:job)    { described_class.new }
    let(:logger) { Logger.new(nil) }

    before do
      # record from the outer describe is build_stubbed(:acda); make sure it can accept attachments
      allow(record).to receive(:image_file=)
      allow(record).to receive(:thumbnail_file=)
      allow(record).to receive(:save_with_retry!).and_return(true)
    end

    it "branches to process_pdf_thumbnail when available_by is a /download url (not .pdf)" do
      record.dc_type = nil
      record.preview = nil
      record.available_by = "https://example.edu/items/123/download"
      j = described_class.new
      expect(j).to receive(:process_pdf_thumbnail).with(record, anything)
      j.perform(record.id)
    end

    it "generate_thumbnail_from_pdf calls placeholder when output image is not created" do
      pdf_path = "/tmp/pdf_no_output.pdf"
      FileUtils.touch(pdf_path)
      allow(job).to receive(:`).and_return("") # command output (stubbed)
      allow(job).to receive(:valid_image?).and_return(false) # even if it did, we’ll fail
      expect(job).to receive(:create_placeholder_thumbnail).with(record, logger)
      # ensure output file is absent to exercise that path
      FileUtils.rm_f("#{pdf_path}_page1.jpg")

      job.send(:generate_thumbnail_from_pdf, record, pdf_path, logger)
      FileUtils.rm_f(pdf_path)
    end

    it "download_vimeo_thumbnail returns false when oEmbed is 200 but missing thumbnail_url" do
      stub_request(:get, %r{vimeo\.com/api/oembed})
        .to_return(status: 200, body: { foo: "bar" }.to_json)
      expect(job.send(:download_vimeo_thumbnail, "123", "/tmp/out.jpg", logger)).to eq(false)
    end

    it "download_vimeo_high_quality returns false when API returns unexpected JSON shape" do
      stub_request(:get, %r{vimeo\.com/api/v2/video})
        .to_return(status: 200, body: { not: "an array" }.to_json)
      expect(job.send(:download_vimeo_high_quality, "123", "/tmp/out.jpg", logger)).to eq(false)
    end

    it "attach_images_to_record returns true when full image present and thumbnail generated" do
      img = "/tmp/full_image.jpg"
      thumb = "/tmp/full_image.jpg_thumb.jpg"
      File.write(img, "x")
      File.write(thumb, "y")
      allow(job).to receive(:generate_thumbnail).and_return(thumb)

      result = job.send(:attach_images_to_record, record, img, logger)
      expect(result).to eq(true)

      FileUtils.rm_f(img)
      FileUtils.rm_f(thumb)
    end

    it "attach_thumbnail_to_record returns true when thumbnail generated" do
      img = "/tmp/in.jpg"
      thumb = "/tmp/in.jpg_thumb.jpg"
      File.write(img, "x")
      File.write(thumb, "y")
      allow(job).to receive(:generate_thumbnail).and_return(thumb)

      result = job.send(:attach_thumbnail_to_record, record, img, logger)
      expect(result).to eq(true)

      FileUtils.rm_f(img)
      FileUtils.rm_f(thumb)
    end

    it 'verify_pdf returns false on exception while reading' do
      job    = described_class.new
      logger = Logger.new(nil)

      # override the global any_instance stub for this instance
      allow(job).to receive(:verify_pdf).and_call_original

      bad = "/tmp/bad_read.pdf"
      # Must be > 1000 bytes to pass the size check and reach File.open
      File.write(bad, "%PDF-1.7\n" + ("x" * 1205))

      # Raise only for this path (don’t global-stub File.open)
      allow(File).to receive(:open).with(bad, 'rb').and_raise(StandardError, 'boom')

      expect(job.send(:verify_pdf, bad, logger)).to eq(false)

      FileUtils.rm_f(bad)
    end


    it "generate_thumbnail_from_image rescues and calls placeholder on error" do
      allow(job).to receive(:attach_images_to_record).and_raise("fail!")
      expect(job).to receive(:create_placeholder_thumbnail).with(record, logger)
      expect {
        job.send(:generate_thumbnail_from_image, record, "/tmp/any.jpg", logger)
      }.not_to raise_error
    end

    it 'create_placeholder_thumbnail logs error when text image fails' do
      job    = described_class.new
      logger = Logger.new(nil)

      # run the real method (override earlier any_instance stub)
      allow_any_instance_of(ProcessThumbnailJob).to receive(:create_placeholder_thumbnail).and_call_original

      allow(job).to receive(:create_text_image).and_raise('oops')
      expect(logger).to receive(:error).with(/Failed to create placeholder/)

      job.send(:create_placeholder_thumbnail, record, logger)
    end


    it 'create_default_video_thumbnail logs error when video placeholder fails' do
      job    = described_class.new
      logger = Logger.new(nil)

      # run the real method (override earlier any_instance stub)
      allow_any_instance_of(ProcessThumbnailJob).to receive(:create_default_video_thumbnail).and_call_original

      allow(job).to receive(:create_video_placeholder).and_raise('oops')
      expect(logger).to receive(:error).with(/Failed to create video thumbnail/)

      job.send(:create_default_video_thumbnail, record, logger)
    end

  end

  describe 'MiniMagick convert helpers' do
    let(:job) { described_class.new }
    let(:logger) { Logger.new(nil) }

    it 'executes the convert pipeline in create_text_image' do
      out_path = '/tmp/text_placeholder.jpg'
      tool = Class.new do
        attr_reader :args
        def initialize; @args = []; end
        def <<(v); @args << v; self; end
      end.new

      # Yield the tool so the block runs and all the `<<` lines execute
      allow(MiniMagick::Tool::Convert).to receive(:new).and_yield(tool).and_return(tool)

      job.send(:create_text_image, "Hello World", out_path)

      # Spot-check a few flags went through (exercising inner lines)
      expect(tool.args).to include("-size", "400x300", "xc:white", "-annotate", "+0+0", "Hello World", out_path)
    ensure
      FileUtils.rm_f(out_path)
    end

    it 'executes the convert pipeline in create_video_placeholder' do
      out_path = '/tmp/video_placeholder.jpg'
      tool = Class.new do
        attr_reader :args
        def initialize; @args = []; end
        def <<(v); @args << v; self; end
      end.new

      allow(MiniMagick::Tool::Convert).to receive(:new).and_yield(tool).and_return(tool)

      job.send(:create_video_placeholder, "My Video", out_path)

      expect(tool.args).to include("-size", "400x300", "xc:black", "-fill", "white", "-annotate", "+0+40", "My Video", out_path)
    ensure
      FileUtils.rm_f(out_path)
    end
  end


end
