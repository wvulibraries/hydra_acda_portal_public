class ExportResultsPresenter
  attr_reader :items_array

  def initialize(raw_response)
    @items_array = raw_response.fetch('response').fetch('docs')
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
