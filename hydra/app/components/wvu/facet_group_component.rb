# frozen_string_literal: true

# OVERRIDE Blacklight v7.40.0 to remove facet hamburger menu from displaying at
#   small screen sizes and also to not let the facets collapse
module Wvu
  class FacetGroupComponent < ::Blacklight::Response::FacetGroupComponent; end
end
