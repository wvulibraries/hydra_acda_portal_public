require 'rails_helper'

RSpec.describe Acda, type: :model do
  let(:acda) { described_class.new }
 
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
      # allow(acda).to receive(:update_preview)
    end
 
    it "formats available_at, preview and available_by URLs" do
      acda.format_urls
      expect(acda).to have_received(:format_url).exactly(3).times
    end
  end
 
  describe "#generate_preview" do
    context "with preservica URL" do
      it "generates thumbnail URL" do
        acda.available_at = "https://test.preservica.com/doc"
        expect(acda.generate_preview).to eq "https://test.preservica.com/download/thumbnail/doc"
      end
    end
 
    context "without preservica URL" do
      it "returns nil" do
        acda.available_at = "https://other.com"
        expect(acda.generate_preview).to be_nil
      end
    end
  end
 
  describe "#clear_empty_fields" do
    it "removes empty strings from relations" do
      acda.creator = [""]
      acda.clear_empty_fields
      expect(acda.creator).to be_empty
    end
  end
 
  describe "#assign_id" do
    it "cleans identifier" do
      allow(acda).to receive(:identifier).and_return("https://test.com/doc?id=123")
      expect(acda.assign_id).to eq "doc_id_123"
    end
  end
 
  describe "callbacks" do
    before do
      acda.available_at = "http://example.com"

  
      allow_any_instance_of(ActiveFedora::Persistence).to receive(:save).and_return(true)

      stub_request(:head, "http://fcrepo:8080/fcrepo/rest/dev")
        .with(
          headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization'=>'Basic ZmVkb3JhQWRtaW46ZmVkb3JhQWRtaW4=',
            'User-Agent'=>'Faraday v2.12.2'
          }
        ).to_return(status: 200, body: "", headers: {})
      
      stub_request(:post, "http://fcrepo:8080/fcrepo/rest/dev")
        .with(
          body: "\n<> <info:fedora/fedora-system:def/model#hasModel> \"Hydra::AccessControl\" .\n",
          headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization'=>'Basic ZmVkb3JhQWRtaW46ZmVkb3JhQWRtaW4=',
            'Content-Type'=>'text/turtle',
            'User-Agent'=>'Faraday v2.12.2'
          }
        ).to_return(status: 200, body: "", headers: {})
      
      stub_request(:post, "http://solr:8983/solr/hydra_dev/update?softCommit=true&wt=json")
        .with(
          body: /.*system_create_dtsi.*system_modified_dtsi.*/,
          headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization'=>'Basic aHlkcmE6bTBOaWY3ck5wM1pwa2lLTjUyTkE=',
            'Content-Type'=>'application/json',
            'User-Agent'=>'Faraday v2.12.2'
          }
        ).to_return(status: 200, body: "", headers: {})
      
      stub_request(:post, "http://fcrepo:8080/fcrepo/rest/dev")
        .with(
          headers: {
            'Accept'=>'*/*',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization'=>'Basic ZmVkb3JhQWRtaW46ZmVkb3JhQWRtaW4=',
            'Content-Type'=>'text/turtle',
            'User-Agent'=>'Faraday v2.12.2'
          }
        ).to_return(status: 200, body: "", headers: {})
    end

    it "calls format_urls before save" do
      expect(acda).to receive(:format_urls)
      acda.run_callbacks(:save)
    end

    it "calls clear_empty_fields_and_generate_thumbnail after save" do
      expect(acda).to receive(:clear_empty_fields_and_generate_thumbnail)
      acda.run_callbacks(:save)
    end
  end
end