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

    # Determines if the provided key represents a local authority.
    #
    # @param key [String] the key to be checked
    # @return [Boolean] true if the key or its pluralized form is found in the local authorities list; false otherwise
    def local_authority?(key)
      local_qa_names = Qa::Authorities::Local.names
      local_qa_names.include?(key.pluralize) || local_qa_names.include?(key)
    end

    # Gets the options for a QA select based on a given key.
    #
    # @param key [String] the key used to fetch the service and retrieve options
    # @return [Array, nil] the options available for the select, or nil if the service does not provide any options
    def options_for_qa_select(key)
      service = fetch_service_for(key)
      service.try(:select_all_options) || service.try(:select_options) || service.new.select_all_options
    end

    private

      # Fetches the service for a given key.
      #
      # @param key [String] the key used to determine the service name
      # @return [Class, nil] the service class based on the key, or nil if it does not exist
      def fetch_service_for(key)
        "#{key.camelize}Service".safe_constantize || "#{key.pluralize.camelize}Service".safe_constantize
      end
  end
end
