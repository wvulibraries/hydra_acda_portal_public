require 'csv'
require 'nokogiri'

class ExportResultsPresenter
  attr_reader :items_array

  def initialize(raw_response)
    @items_array = raw_response.fetch('response').fetch('docs')
  end

  # @return [Array]
  def to_csv
    csv_data = solr_docs.map(&:to_semantic_values)
    headers = csv_data.flat_map(&:keys).uniq

    CSV.generate(headers: true) do |csv|
      csv << headers
      csv_data.each do |item|
         csv << headers.map { |header| flatten(item[header]) }
      end
    end
  end

  # @return [String]
  def to_xml
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.items {
        solr_docs.each do |doc|
          semantic_values = doc.to_semantic_values
          xml.item {
            semantic_values.each do |key, value|
              xml.send(key.to_sym, flatten(value))
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
end
