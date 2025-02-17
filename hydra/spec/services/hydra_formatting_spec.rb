require 'rails_helper'

RSpec.describe HydraFormatting do
	describe ".valid_string" do
		it "returns nil for empty string" do
			expect(described_class.valid_string("")).to be_nil
		end
 
		it "returns original string if not empty" do
			expect(described_class.valid_string("test")).to eq("test")
		end
	end
 
	describe ".split_subjects" do
		it "returns nil for empty string" do
			expect(described_class.split_subjects("")).to be_nil
		end
 
		it "splits string on |||" do
			expect(described_class.split_subjects("one|||two|||three")).to eq(["one", "two", "three"])
		end
	end
 
	describe ".remove_special_chars" do
		it "returns nil for empty string" do
			expect(described_class.remove_special_chars("")).to be_nil
		end
 
		it "removes newlines, carriage returns and tabs" do
			expect(described_class.remove_special_chars("test\ntest\rtest\ttest")).to eq("testtesttest test")
		end
	end
 
	describe ".decode_html" do
		it "returns nil for empty string" do
			expect(described_class.decode_html("")).to be_nil
		end
 
		it "decodes HTML entities" do
			expect(described_class.decode_html("&amp;")).to eq("&")
		end
	end
 
	describe ".mime_type" do
		
		it "returns correct mime type for PDF" do
			expect(described_class.mime_type("test.pdf")).to eq("application/pdf")
		end
 
		it "returns correct mime type for JPG" do
			expect(described_class.mime_type("image.jpg")).to eq("image/jpeg")
		end
 
		it "handles files without extension" do
			expect { described_class.mime_type("noextension") }.not_to raise_error
		end
	end
 
	describe ".predicatable_array" do
		it "converts hash to array of values" do
			expect(described_class.predicatable_array({a: 1, b: 2})).to eq([1, 2])
		end
 
		it "wraps string in array" do
			expect(described_class.predicatable_array("test")).to eq(["test"])
		end
	end
 end