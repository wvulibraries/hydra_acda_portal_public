# frozen_string_literal: true

module BlacklightRangeLimit
  module RangeFormComponentDecorator
    private

    ##
    # the form needs to serialize any search parameters, including other potential range filters,
    # as hidden fields. The parameters for this component's range filter are serialized as number
    # inputs, and should not be in the hidden params.

    # OVERRIDE: We need to include a dummy search_field parameter if none exists,
    # to trick blacklight into displaying actual search results instead
    # of home page. Not a great solution, but easiest for now.

    # @return [Blacklight::HiddenSearchStateComponent]
    def hidden_search_state
      hidden_search_params = @facet_field.search_state.params_for_search.except(:utf8, :page)
      hidden_search_params[:range]&.except!(@facet_field.key)
      special_params = {"search_field"=>"dummy_range"}

      Blacklight::HiddenSearchStateComponent.new(params: hidden_search_params.merge(special_params))
    end
  end
end

BlacklightRangeLimit::RangeFormComponent.prepend BlacklightRangeLimit::RangeFormComponentDecorator
