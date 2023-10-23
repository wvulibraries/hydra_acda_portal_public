class ChicagoCitationService
  def format(doc)
    # format is based off of https://www.loc.gov/programs/teachers/getting-started-with-primary-sources/citing/chicago/
    text = ""

    creator = sanitize_value(doc['creator_tesim']&.first)
    title = sanitize_value(doc['title_tesim']&.first || doc['description_tesim']&.first)
    date = sanitize_value(doc['date_tesim']&.first)
    location = sanitize_value(physical_location(doc))
    contributing_institution = sanitize_value(doc['contributing_institution_tesim']&.first)
    # TODO get URL for show page
    url = nil
    access_date = Date.today.strftime("%B %d, %Y")

    text << "#{creator}. " if creator
    text << "<i>#{title}</i>. " if title
    text << "#{date}. " if date
    text << "#{location}. " if location
    text << "#{contributing_institution}. " if contributing_institution
    text << "#{url}" if url
    text << " (accessed #{access_date})." if url

    text.strip.html_safe
  end

  private

    def collection_number(doc)
      match = doc['physical_location_tesim']&.first&.match(/collection (\d+)/i)
      match ? match[1] : nil
    end

    def box_number(doc)
      match = doc['physical_location_tesim']&.first&.match(/box (\d+)/i)
      match ? match[1] : nil
    end

    def folder_number(doc)
      match = doc['physical_location_tesim']&.first&.match(/folder (\d+)/i)
      match ? match[1] : nil
    end

    def physical_location(doc)
      collection = collection_number(doc)
      box = box_number(doc)
      folder = folder_number(doc)

      if collection || box || folder
        location = ""
        location << "Collection #{collection}, " if collection
        location << "Box #{box}, " if box
        location << "Folder #{folder}" if folder

        location.strip.chomp(',')
      else
        doc['physical_location_tesim']&.first
      end
    end

    def sanitize_value(value)
      Loofah.fragment(value.to_s).scrub!(:strip).to_s
    end
end