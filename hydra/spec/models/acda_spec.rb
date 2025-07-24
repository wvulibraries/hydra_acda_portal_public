require 'rails_helper'

RSpec.describe Acda, type: :model do
  
  let(:acda) { build(:acda) }

  describe "properties" do
    it { is_expected.to have_property :title }
    it { is_expected.to have_property :date }
    it { is_expected.to have_property :creator }
    it { is_expected.to have_property :preview }
    it { is_expected.to have_property :available_at }
  end
 
  describe "#format_urls" do
    before do
      allow(acda).to receive(:format_url).and_return("http://formatted.com")
      allow(acda).to receive(:resolve_redirect).and_return("http://formatted.com")
    end

 
    it "formats available_at, preview and available_by URLs" do
      acda.format_urls
      expect(acda).to have_received(:format_url).exactly(3).times
      expect(acda).to have_received(:resolve_redirect).once
    end
  end
 
  describe "#generate_preview" do
    context "with preservica URL" do
      it "generates thumbnail URL" do
        expect(acda.generate_preview("https://test.preservica.com/doc")).to eq "https://test.preservica.com/download/thumbnail/doc"
      end
    end
 
    context "with a normal URL" do
      it "returns the same URL" do
        expect(acda.generate_preview("https://other.com"))
          .to eq "https://other.com"
      end
    end

    context "with a downloadable URL" do
      it "returns nil for /download or .pdf" do
        expect(acda.generate_preview("https://example.com/download/file.pdf")).to be_nil
      end
    end

    context "with nil URL" do
      it "returns nil" do
        expect(acda.generate_preview(nil)).to be_nil
      end
    end
  end
 
  describe "#clear_empty_fields" do
    it "removes empty strings from relations" do
      acda.creator = [""]
      acda.clear_empty_fields
      expect(acda.creator).to be_empty
    end

    it "keeps non-blank values but removes empty ones" do
      acda.creator = ["", "John Doe", ""]
      acda.clear_empty_fields
      expect(acda.creator).to eq(["John Doe"])
    end
  end
 
  describe "#assign_id" do
    it "cleans identifier by removing protocol and special characters" do
      allow(acda).to receive(:identifier).and_return("https://test.com/doc?id=123")
      expect(acda.assign_id).to eq "doc_id_123"
    end
  end
 
  # describe "callbacks" do
  #   before do
  #     acda.available_at = "http://example.com"

  
  #     allow_any_instance_of(ActiveFedora::Persistence).to receive(:save).and_return(true)

  #     stub_request(:head, "http://fcrepo:8080/fcrepo/rest/dev")
  #       .with(
  #         headers: {
  #           'Accept'=>'*/*',
  #           'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  #           'Authorization'=>'Basic ZmVkb3JhQWRtaW46ZmVkb3JhQWRtaW4=',
  #           'User-Agent'=>'Faraday v2.12.2'
  #         }
  #       ).to_return(status: 200, body: "", headers: {})
      
  #     stub_request(:post, "http://fcrepo:8080/fcrepo/rest/dev")
  #       .with(
  #         body: "\n<> <info:fedora/fedora-system:def/model#hasModel> \"Hydra::AccessControl\" .\n",
  #         headers: {
  #           'Accept'=>'*/*',
  #           'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  #           'Authorization'=>'Basic ZmVkb3JhQWRtaW46ZmVkb3JhQWRtaW4=',
  #           'Content-Type'=>'text/turtle',
  #           'User-Agent'=>'Faraday v2.12.2'
  #         }
  #       ).to_return(status: 200, body: "", headers: {})
      
  #     stub_request(:post, "http://solr:8983/solr/hydra_dev/update?softCommit=true&wt=json")
  #       .with(
  #         body: /.*system_create_dtsi.*system_modified_dtsi.*/,
  #         headers: {
  #           'Accept'=>'*/*',
  #           'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  #           'Authorization'=>'Basic aHlkcmE6bTBOaWY3ck5wM1pwa2lLTjUyTkE=',
  #           'Content-Type'=>'application/json',
  #           'User-Agent'=>'Faraday v2.12.2'
  #         }
  #       ).to_return(status: 200, body: "", headers: {})
      
  #     stub_request(:post, "http://fcrepo:8080/fcrepo/rest/dev")
  #       .with(
  #         headers: {
  #           'Accept'=>'*/*',
  #           'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  #           'Authorization'=>'Basic ZmVkb3JhQWRtaW46ZmVkb3JhQWRtaW4=',
  #           'Content-Type'=>'text/turtle',
  #           'User-Agent'=>'Faraday v2.12.2'
  #         }
  #       ).to_return(status: 200, body: "", headers: {})
  #   end

  #   it "calls format_urls before save" do
  #     expect(acda).to receive(:format_urls)
  #     acda.run_callbacks(:save)
  #   end

  #   it "calls clear_empty_fields_and_generate_thumbnail after save" do
  #     expect(acda).to receive(:clear_empty_fields_and_generate_thumbnail)
  #     acda.run_callbacks(:save)
  #   end
  # end


  describe "#needs_thumbnail_update?" do
    before do
      # Prevent Fedora HTTP calls entirely
      allow(acda).to receive(:image_file).and_return(nil)
      allow(acda).to receive(:thumbnail_file).and_return(nil)
    end

    it "returns true if both image_file and thumbnail_file are blank" do
      expect(acda.needs_thumbnail_update?).to eq(true)
    end

    it "returns true if preview changed" do
      allow(acda).to receive(:saved_change_to_preview?).and_return(true)
      expect(acda.needs_thumbnail_update?).to eq(true)
    end

    it "returns true if available_by changed" do
      allow(acda).to receive(:saved_change_to_available_by?).and_return(true)
      expect(acda.needs_thumbnail_update?).to eq(true)
    end

    it "returns false if nothing changed and thumbnails exist" do
      # Simulate that image_file and thumbnail_file exist
      fake_file = double("AcdaFile")
      allow(fake_file).to receive(:blank?).and_return(false)
      allow(acda).to receive(:image_file).and_return(fake_file)
      allow(acda).to receive(:thumbnail_file).and_return(fake_file)
      allow(acda).to receive(:saved_change_to_preview?).and_return(false)
      allow(acda).to receive(:saved_change_to_available_by?).and_return(false)
      allow(acda).to receive(:saved_change_to_available_at?).and_return(false)

      expect(acda.needs_thumbnail_update?).to eq(false)
    end
  end

  describe "#handle_thumbnail_generation" do
    it "queues a job if thumbnail update is needed" do
      allow(acda).to receive(:needs_thumbnail_update?).and_return(true)
      allow(ProcessThumbnailJob).to receive(:perform_once)

      acda.handle_thumbnail_generation

      expect(acda.skip_thumbnail_update).to eq(true)
      expect(ProcessThumbnailJob).to have_received(:perform_once).with(acda.id)
    end

    it "does nothing if queued_job is already true" do
      acda.queued_job = 'true'
      allow(ProcessThumbnailJob).to receive(:perform_once)

      acda.handle_thumbnail_generation

      expect(ProcessThumbnailJob).not_to have_received(:perform_once)
    end

    it "does nothing if needs_thumbnail_update? is false" do
      allow(acda).to receive(:needs_thumbnail_update?).and_return(false)
      allow(ProcessThumbnailJob).to receive(:perform_once)

      acda.handle_thumbnail_generation

      expect(ProcessThumbnailJob).not_to have_received(:perform_once)
    end
  end

  describe ".queue_pending_thumbnails" do
    it "queues records that have preview present and no queued_job" do
      record = build_stubbed(:acda, preview: "https://example.com/image.jpg", queued_job: nil)

      # Stub the entire chain: where(...).find_each { |r| ... }
      allow(described_class)
        .to receive_message_chain(:where, :find_each)
        .and_yield(record)

      allow(record).to receive(:save_with_retry!)
      allow(DownloadAndSetThumbsJob).to receive(:set).and_return(DownloadAndSetThumbsJob)
      allow(DownloadAndSetThumbsJob).to receive(:perform_later)

      described_class.queue_pending_thumbnails

      expect(record.queued_job).to eq('true')
      expect(DownloadAndSetThumbsJob).to have_received(:set)
      expect(DownloadAndSetThumbsJob).to have_received(:perform_later).with(record.id)
    end

    it "skips records without preview" do
      record = build_stubbed(:acda, preview: nil, queued_job: nil)

      allow(described_class)
        .to receive_message_chain(:where, :find_each)
        .and_yield(record)

      allow(DownloadAndSetThumbsJob).to receive(:set)

      described_class.queue_pending_thumbnails

      expect(DownloadAndSetThumbsJob).not_to have_received(:set)
    end
  end




  describe ".with_thumbnail_lock" do
    it "sets queued_job, yields, and marks completed" do
      record = build_stubbed(:acda, id: "abc", queued_job: nil)
      allow(record).to receive(:save_with_retry!).and_return(true)
      allow(described_class).to receive(:find).with("abc").and_return(record)

      yielded = nil
      result = described_class.with_thumbnail_lock("abc") { |locked| yielded = locked }

      expect(result).to eq(true)

      # Normalize the ID in case CI returns a Fedora URL like http://test/abc
      normalized_id = yielded.id.to_s.split('/').last
      expect(normalized_id).to eq("abc")

      expect(record.queued_job).to eq("completed")
    end

    it "returns false if already queued" do
      record = build_stubbed(:acda, id: "queued", queued_job: "true")
      allow(described_class).to receive(:find).with("queued").and_return(record)

      expect(described_class.with_thumbnail_lock("queued")).to eq(false)
    end

    it "handles errors in the block and still marks completed" do
      record = build_stubbed(:acda, id: "err", queued_job: nil)
      allow(record).to receive(:save_with_retry!).and_return(true)
      allow(described_class).to receive(:find).with("err").and_return(record)

      result = described_class.with_thumbnail_lock("err") { raise "failure" }
      expect(result).to eq(false)
      expect(record.queued_job).to eq("completed")
    end
  end

end