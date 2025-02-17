require 'rails_helper'
require 'blacklight'

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

  describe "#local_authority?" do
    context 'when key is valid' do
      it "checks if the key exists in QA::Authorities::Local.names" do
        valid_local_authorities = search_fields_for_advanced_search.select { |key, _value| local_authority?(key) }

        valid_local_authorities.each_key do |key|
          expect(local_authority?(key)).to be true
        end
      end
    end

    context 'when the key is invalid' do
      it "checks if the key exists in QA::Authorities::Local.names" do
        invalid_local_authorities = search_fields_for_advanced_search.reject { |key, _value| local_authority?(key) }

        invalid_local_authorities.each_key do |key|
          expect(local_authority?(key)).to be false
        end
      end
    end
  end

  describe "#options_for_qa_select?" do
    it "returns the values for a given key" do
      valid_local_authority_keys = search_fields_for_advanced_search.select { |key, _value| local_authority?(key) }.keys

      valid_local_authority_keys.each do |key|
        local_authority_terms = fetch_local_yml(key)['terms'].map { |term| [term['term'], term['id']] }

        expect(options_for_qa_select(key)).to eq(local_authority_terms)
      end
    end
  end

  # a utility method for finding the correct yml files because the naming is inconsistent, plural vs singular
  def fetch_local_yml(key)
    YAML.load_file("config/authorities/#{key}.yml")
  rescue Errno::ENOENT
    YAML.load_file("config/authorities/#{key.pluralize}.yml")
  end

  describe "#fetch_service_for" do
    it "returns the service class for a given a valid key" do
      expect(fetch_service_for('congress')).to eq(CongressService)
    end

    it "returns the service even if it should have been plural" do
      expect(fetch_service_for('congress')).to eq(CongressService)
    end

    it "returns nil for an invalid key" do
      expect(fetch_service_for('foo')).to be_nil
    end
  end
end
