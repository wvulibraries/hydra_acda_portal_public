require 'net/http'
require 'addressable/uri'

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
    preview = document[:preview_tesim]&.first.to_s
    id = document[:id]

    if is_active_url?(preview)
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

  def format_url(url)
    return url if url.blank?
    url.match?(/\Ahttp(s)?:\/\//) ? sanitize_url(url) : "https://#{sanitize_url(url)}" # Add scheme if missing
  end

  def is_active_url?(url)
    return false if url.blank?

    begin
      resolved_url = resolve_redirect(url) # Resolve any redirects
      uri = URI.parse(resolved_url)
      response = Net::HTTP.get_response(uri)

      # Check if the response indicates success or redirection
      response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection)
    rescue URI::InvalidURIError => e
      Rails.logger.error "Invalid URL: #{url}. #{e.message}"
      false
    rescue StandardError => e
      Rails.logger.error "Failed to check URL activity for #{url}: #{e.message}"
      false
    end
  end

  # Using this instead of #link_to_facet in the catalog_controller was giving us just strings instead of
  # html safe displays for some reason, so we're using this helper method instead.
  def render_html_safe_facet(**kwargs)
    values = kwargs[:value]
    field = kwargs[:field].gsub('_tesim', '_sim')

    display_value = ''
    values.each do |value|
      params = { q: '', f: { field => [value], search_field: 'all_fields' } }
      display_value << link_to(value, search_action_path(params))
    end

    display_value.html_safe
  end

  # Specifically used for date_ssim in conjunction with the range limit
  def render_date_facet(**kwargs)
    values = kwargs[:value]
    field = kwargs[:field].gsub('_tesim', '_ssim')

    display_value = ''
    values.each do |value|
      params = { q: '', range: { field => { begin: value, end: value } } }
      display_value << link_to(value, search_action_path(params))
    end

    display_value.html_safe
  end

  def resolve_redirect(url)
    sanitized_url = sanitize_url(url) # Sanitize the URL before parsing
    uri = URI.parse(sanitized_url)
    response = Net::HTTP.get_response(uri)

    case response
    when Net::HTTPRedirection
      # Follow the redirect and resolve recursively
      location = response['location']
      Rails.logger.info "Redirected: #{url} -> #{location}"
      resolve_redirect(location)
    else
      # Return the current URL if no redirects
      sanitized_url
    end
  rescue URI::InvalidURIError => e
    Rails.logger.error "Invalid URL while resolving redirect: #{url}. #{e.message}"
    url # Return the original URL in case of an error
  rescue StandardError => e
    Rails.logger.error "Failed to resolve URL #{url}: #{e.message}"
    url
  end

  def sanitize_url(url)
    Addressable::URI.parse(url).normalize.to_s
  end

  def record_has_thumbnail?(id)
    record = Acda.find(id)
    record.thumbnail_file.present?
  end

end
