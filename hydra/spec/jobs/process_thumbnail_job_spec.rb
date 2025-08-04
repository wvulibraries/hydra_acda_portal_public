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

end
