module ApplicationHelper

  def application_name
    'American Congress Digital Archives Portal'
  end

  def application_header
    'American Congress Digital Archives Portal'
  end

  def render_page_description
    'The American Congress Digital Archives Portal is a collaborative, non-partisan project that aggregates congressional archives held by multiple institutions and makes the archives available online.'
  end

  def render_key_words
    'congress, government, legislation, policy, politics'
  end

  def render_html_safe_url(document)
    # link_to document[:value].to_s.html_safe
    link_to document[:value].first, document[:value].first.html_safe
  end

  def catalog_page_render
    # if any params exist render search results partial
    if params[:q] || params[:f] || params[:search_field]
      'search_results'
    else
      'home_text'
    end
  end

  def render_thumbnail(document, options = {})
    description = document[:description_tesim].to_s
    title = document[:title_tesim]&.first.to_s
    preview = document[:preview_ssim]&.first
    id = document[:id]

    if preview.present? && is_active_url?(preview)
      image_tag(preview, title: title, alt: description, class: "full-size-responsive")
    elsif document.thumbnail_file?
      image_tag("/thumb/#{id}.jpg", title: title, alt: description, class: "full-size-responsive")
    elsif document[:dc_type_ssi] == "Sound"
      link_to_document document, render(partial: 'catalog/audio_button'), class: "button audio-button"
    elsif document[:dc_type_ssi]&.include?("Moving")
      link_to_document document, render(partial: 'catalog/video_button'), class: "button video-button"
    elsif !document.image_file? && document[:dc_type_ssi] == "Text"
      link_to_document document, render(partial: 'catalog/pdf_button'), class: "button pdf-button"
    else
      link_to_document document, render(partial: 'catalog/image_slash'), class: "button image-slash"
    end
  end

  def is_active_url?(url)
    # Example implementation: checks if the URL is accessible
    return false if url.blank?

    begin
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)
      response.is_a?(Net::HTTPSuccess)
    rescue
      false
    end
  end

  # Using this instead of #link_to_facet in the catalog_controller was giving us just strings instead of
  # html safe displays for some reason, so we're using this helper method instead.
  def render_html_safe_url(**kwargs)
    values = kwargs[:value]
    field = kwargs[:field]

    display_value = ''
    values.each do |value|
      display_value << link_to(value, search_action_path("f[#{field}][]" => value, search_field: 'all_fields'))
    end

    display_value.html_safe
  end
end
