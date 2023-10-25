require 'nokogiri'

# Responsible for formating XML results from a Blacklight search response
class ExportXmlPresenter < ExportResultsPresenter
  # @return [String]
  def to_xml
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.records {
        solr_docs.each do |doc|
          semantic_values = doc.to_semantic_values
          xml.record {
            semantic_values.each do |key, value|
              xml.send(key.to_sym, flatten(value))
            end
          }
        end
      }
    end
    builder.to_xml
  end
end
