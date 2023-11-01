module ChicagoCitationService
  class << self
    def format(document:, original_url:)
      # format is based off of https://www.loc.gov/programs/teachers/getting-started-with-primary-sources/citing/chicago/
      text = ""

      title = sanitize_value(document['title_tesim']&.first || document['description_tesim']&.first)
      date = sanitize_value(document['date_tesim']&.first)
      location = sanitize_value(document['physical_location_tesim']&.first)
      collection_title = sanitize_value(document['collection_title_tesim']&.first)
      contributing_institution = sanitize_value(document['contributing_institution_tesim']&.first)
      url = original_url
      access_date = Date.today.strftime("%B %d, %Y")

      text << "<i>#{title}</i>, " if title.present?
      text << "#{date}, " if date.present?
      text << "#{location}, " if location.present?
      text << "#{collection_title}, " if collection_title.present?
      text << "#{contributing_institution}. " if contributing_institution.present?
      text << "#{url} (accessed #{access_date})."

      text.strip.html_safe
    end

    private

      def sanitize_value(value)
        Loofah.fragment(value.to_s).scrub!(:strip).to_s
      end
    end
end
