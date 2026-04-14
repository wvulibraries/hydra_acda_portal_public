# app/components/blacklight/start_over_button_component.rb
module Blacklight
  class StartOverButtonComponent < Blacklight::Component
    def call
      link_to t('blacklight.search.start_over'), start_over_path, class: 'catalog_startOverLink btn btn-primary'
    end

    private

    def start_over_path
      # Relative path to the search page with empty query
      '/?q=&search_field=all_fields'
    end
  end
end