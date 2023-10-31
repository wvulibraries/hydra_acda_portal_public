class Indexer < ActiveFedora::IndexingService
  def generate_solr_document
    super.tap do |solr_doc|
      add_date(solr_doc)
    end
  end

  private

    def add_date(solr_doc)
      # The allowed date formats are either YYYY, YYYY-MM, or YYYY-MM-DD
      # the date must be formatted as a 4 digit year in order to be sorted.
      valid_date_formats = /\A(\d{4})(?:-\d{2}(?:-\d{2})?)?\z/
      date_string = solr_doc['edtf_ssi']
      year = date_string&.match(valid_date_formats)&.captures&.first
      solr_doc['date_ssi'] = year if year
    end
end
