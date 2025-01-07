require 'csv'
require 'nokogiri'

class ExportResultsPresenter
  attr_reader :items_array

  def initialize(raw_response)
    @items_array = raw_response.fetch('response').fetch('docs')
  end

  # @return [String]
  def to_csv
    csv_data = solr_docs.map(&:to_semantic_values)
    headers = csv_data.flat_map(&:keys).uniq
    headers.delete(:bulkrax_identifier)

    # convert headers (which are the keys of the semantic values) to the metadata terms
    mapped_headers = headers.map { |header| metadata_term_mapping[header.to_s] || header }

    CSV.generate(headers: true) do |csv|
      csv << mapped_headers
      csv_data.each do |item|
        # remove the acda url from the identifier
        remove_acda_url(item)
        csv << headers.map { |header| flatten(item[header]) }
      end
    end
  end

  # @return [String]
  def to_xml
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.items(
        'xmlns:dcterms' => 'http://purl.org/dc/terms/',
        'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
        'xmlns:edm' => 'http://www.europeana.eu/schemas/edm/'
        ) {
        solr_docs.each do |doc|
          semantic_values = doc.to_semantic_values
          semantic_values.delete(:bulkrax_identifier)
          remove_acda_url(semantic_values)
          xml.item {
            semantic_values.each do |key, value|
              sanitized_key = sanitize(metadata_term_mapping[key.to_s] || key)
              xml.send(sanitized_key, flatten(value))
            end
          }
        end
      }
    end
    builder.to_xml
  end

  private

    # flatten values for one column
    def flatten(column_data)
      return column_data unless column_data.is_a?(Array)

      combined_value = column_data.join('; ')
    end

    def solr_docs
      items_array.map { |item_hash| SolrDocument.new(item_hash) }
    end

    # Looks up the Bulkrax field mappings to get the metadata term for a given property
    def metadata_term_mapping
      mappings_hash = Bulkrax.config.field_mappings['Bulkrax::CsvParser'].each_with_object({}) do |(k, v), hash|
        hash[k] = v[:from].first
      end
      mappings_hash.delete('bulkrax_identifier')
      mappings_hash
    end

    def sanitize(key)
      return special_xml_mappings[key] if special_xml_mappings.key?(key)

      if key.count(':') > 1
        prefix = key.split(':', 2).first
        term = key.split('/').last
        return "#{prefix}:#{term}"
      end

      key
    end

    # These mappings are special cases that don't follow the normal pattern
    def special_xml_mappings
      {
        'http://purl.org/dc/elements/1.1/subject' => 'dc:subject',
        'dcterms:http://purl.org/dc/terms/type' => 'dc:type'
      }
    end

    def remove_acda_url(hash)
      hash[:identifier].gsub!(SolrDocument::ACDA_URL, '')
    end
end
