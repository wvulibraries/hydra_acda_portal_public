class Indexer < ActiveFedora::IndexingService
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['has_image_file_bsi'] = object.image_file.present?
      solr_doc['has_thumbnail_file_bsi'] = object.thumbnail_file.present?
      if EDTF.parse(solr_doc['edtf_ssi'])
        solr_doc['date_ssim'] = add_date(solr_doc)
      end
    end
  end

  private

    def add_date(solr_doc)
      date = Date.edtf!(solr_doc['edtf_ssi'].downcase)

      if date.is_a?(EDTF::Interval)
        date.map(&:year).uniq
      else
        date.year
      end
    end
end
