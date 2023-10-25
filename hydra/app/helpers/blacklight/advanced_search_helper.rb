# frozen_string_literal: true

module Blacklight
  # Helpers related to the advanced search functionality of Blacklight.
  module AdvancedSearchHelper
    # Adjust number to show more or less primary fields in the advanced search form.
    NUMBER_OF_PRIMARY_FIELDS = 4

    # Retrieves the first four search fields from a given collection.
    #
    # @param fields [Array] collection of search fields
    # @return [Array] a subset of the input collection containing the first four fields
    def primary_search_fields_for(fields)
      fields.each_with_index.partition { |_, idx| idx < NUMBER_OF_PRIMARY_FIELDS }.first.map(&:first)
    end

    # Retrieves all search fields from a given collection except the first four.
    #
    # @param fields [Array] collection of search fields
    # @return [Array] a subset of the input collection excluding the first four fields
    def secondary_search_fields_for(fields)
      fields.each_with_index.partition { |_, idx| idx < NUMBER_OF_PRIMARY_FIELDS }.last.map(&:first)
    end
  end
end
