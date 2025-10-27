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
 
    context "without preservica URL" do
      it "returns as it is" do
        expect(acda.generate_preview("https://other.com")).to eq "https://other.com"
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
 
end