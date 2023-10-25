require 'csv'
# Responsible for formating csv results from a Blacklight search response
class ExportCsvPresenter
  attr_reader :items_array

  def initialize(raw_response)
    @items_array = raw_response.fetch('response').fetch('docs')
  end

  # @return [Array]
  def to_csv
    csv_data = @items_array.map{|item_hash| SolrDocument.new(item_hash)}.map(&:to_semantic_values)
    headers = csv_data.flat_map(&:keys).uniq

    CSV.generate(headers: true) do |csv|
      csv << headers
      csv_data.each do |item|
         csv << headers.map { |header| flatten(item[header]) }
      end
    end
  end

  private

    # flatten values for one column
    def flatten(column_data)
      combined_value = ''
      return column_data unless column_data.is_a?(Array)
      combined_value = column_data.join('; ')
    end
end
