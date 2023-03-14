# frozen_string_literal: true

# OVERRIDE BULKRAX 5 to change required elements
# temporary until bulkrax is fixed. xx
module Bulkrax
  module CsvParserDecorator
    # @return [Array<String>]
    def required_elements
      if Bulkrax.fill_in_blank_source_identifiers
        ['dcterms:title']
      else
        ['title', source_identifier]
      end
    end
  end
end

Bulkrax::CsvParser.prepend(Bulkrax::CsvParserDecorator)
