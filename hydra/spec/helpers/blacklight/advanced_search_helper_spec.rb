require 'rails_helper'

RSpec.describe Blacklight::AdvancedSearchHelper do
  include described_class

  let(:search_fields_for_advanced_search) { CatalogController.blacklight_config.search_fields.select { |_k, v| v.include_in_advanced_search || v.include_in_advanced_search.nil? } }

  describe "#primary_search_fields" do
    it "returns the primary search fields" do
      expect(primary_search_fields_for(search_fields_for_advanced_search).size).to eq(Blacklight::AdvancedSearchHelper::NUMBER_OF_PRIMARY_FIELDS)
    end

    it "returns the client specified advanced search fields" do
      expect(primary_search_fields_for(search_fields_for_advanced_search).map { |search| search.last.key }).to eq(["creator", "date", "names", "title"])
    end
  end

  describe "#secondary_search_fields" do
    it "returns the secondary search fields" do
      second_search_fields_count = search_fields_for_advanced_search.size - Blacklight::AdvancedSearchHelper::NUMBER_OF_PRIMARY_FIELDS

      expect(secondary_search_fields_for(search_fields_for_advanced_search).size).to eq(second_search_fields_count)
    end
  end
end
