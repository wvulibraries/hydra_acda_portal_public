require 'csv'

# Responsible for formating csv results from a Blacklight search response
class ExportCsvPresenter < ExportResultsPresenter
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
end
