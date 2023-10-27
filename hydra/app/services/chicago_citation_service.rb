module ChicagoCitationService
  class << self
    def format(document:, original_url:)
      # format is based off of https://www.loc.gov/programs/teachers/getting-started-with-primary-sources/citing/chicago/
      text = ""

      title = sanitize_value(document['title_ssi'] || document['description_ssi'])
      date = sanitize_value(document['date_ssi'])
      location = sanitize_value(document['physical_location_ssi'])
      contributing_institution = sanitize_value(document['contributing_institution_ssi'])
      url = original_url
      access_date = Date.today.strftime("%B %d, %Y")

      text << "<i>#{title}</i>, " if title.present?
      text << "#{date}, " if date.present?
      text << "#{location}, " if location.present?
      text << "#{contributing_institution}. " if contributing_institution.present?
      text << "#{url}"
      text << " (accessed #{access_date})."

      text.strip.html_safe
    end

    private

      def collection_number(doc)
        match = doc['physical_location_ssi']&.match(/collection (\d+)/i)
        match ? match[1] : nil
      end

      def box_number(doc)
        match = doc['physical_location_ssi']&.match(/box (\d+)/i)
        match ? match[1] : nil
      end

      def folder_number(doc)
        match = doc['physical_location_ssi']&.match(/folder (\d+)/i)
        match ? match[1] : nil
      end

      def sanitize_value(value)
        Loofah.fragment(value.to_s).scrub!(:strip).to_s
      end
    end
end
