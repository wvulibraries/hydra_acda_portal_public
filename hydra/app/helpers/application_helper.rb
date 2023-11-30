module ApplicationHelper
  
  def application_name
    'American Congress Digital Archives Portal'
  end

  def application_header
    'American Congress Digital Archives Portal'
  end

  def render_page_description
    'change me'
  end

  def render_key_words
    'change me'
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
end
