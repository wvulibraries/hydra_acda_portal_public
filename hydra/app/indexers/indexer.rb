class Indexer < ActiveFedora::IndexingService
  def generate_solr_document
    super.tap do |solr_doc|
      add_date(solr_doc)
    end
  end

  private

    def add_date(solr_doc)
      date_string = solr_doc['edtf_ssi']

      # If there is no date, set it to 'unknown', otherwise it would be blank and show up first in an ascending sort
      return solr_doc['date_ssi'] = 'unknown' if date_string.blank?

      # Check for 'YYYYs' or "YYYY's" format and convert it to just 'YYYY'
      year_match = date_string&.match(/\b(\d{4})(?:'s|s)\b/)
      return solr_doc['date_ssi'] = year_match[1] if year_match # Just the year

      begin
        # Use Date.parse for other cases
        date = Date.parse(date_string)
        # Determine the format needed based on the precision of the original date string
        if date_string.match(/\b\d{4}-\d{2}-\d{2}\b/)
          formatted_date = date.strftime('%Y-%m-%d') # YYYY-MM-DD
        elsif date_string.match(/\b\d{4}-\d{2}\b/)
          formatted_date = date.strftime('%Y-%m') # YYYY-MM
        else
          formatted_date = date.strftime('%Y') # YYYY
        end
        solr_doc['date_ssi'] = formatted_date
      rescue ArgumentError
        # If Date.parse fails to parse the date_string, it could be a simple year or an unsupported format.
        # In such a case, fallback to regex to extract the year.
        year_match = date_string&.match(/\b(\d{4})\b/)
        solr_doc['date_ssi'] = year_match[1] if year_match
      end
    end
end
