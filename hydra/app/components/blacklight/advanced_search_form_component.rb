# frozen_string_literal: true

# OVERRIDE Blacklight::AdvancedSearchFormComponent v 7.40.0 to
#   - show only first 4 primary fields
#   - fix issue with search_field hidden field not being included in the form
#   - show options for QA select fields
module Blacklight
  class AdvancedSearchFormComponent < SearchBarComponent
    include Blacklight::ContentAreasShim
    # Adjust number to show more or less primary fields in the advanced search form.
    NUMBER_OF_PRIMARY_FIELDS = 4

    renders_many :constraints
    renders_many :primary_search_field_controls
    renders_many :secondary_search_field_controls
    renders_many :search_filter_controls, (lambda do |config:, display_facet:, presenter: nil, component: nil, **kwargs|
      presenter ||= (config.presenter || Blacklight::FacetFieldPresenter).new(config, display_facet, helpers)
      component = component || config.advanced_search_component || Blacklight::FacetFieldCheckboxesComponent
      component.new(facet_field: presenter, **kwargs)
    end)

    def initialize(response:, **options)
      super(**options)
      @response = response
    end

    def before_render
      initialize_primary_search_field_controls if primary_search_field_controls.blank?
      initialize_secondary_search_field_controls if secondary_search_field_controls.blank?
      initialize_search_filter_controls if search_filter_controls.blank?
      initialize_constraints if constraints.blank?
    end

    # Override to add render hash as hidden fields so advanced search will work
    def default_operator_menu
      options_with_labels = [:must, :should].index_by { |op| t(op, scope: 'blacklight.advanced_search.op') }
      label_tag(:op, t('blacklight.advanced_search.op.label'), class: 'sr-only visually-hidden') + select_tag(:op, options_for_select(options_with_labels, params[:op]), class: 'input-small') + render_hash_as_hidden_fields({ search_field: 'advanced' })
    end

    def sort_fields_select
      options = sort_fields.values.map { |field_config| [helpers.sort_field_label(field_config.key), field_config.key] }
      return unless options.any?

      select_tag(:sort, options_for_select(options, params[:sort]), class: "form-select custom-select sort-select w-auto", aria: { labelledby: 'advanced-search-sort-label' })
    end

    private

    def qa_options(key)
      select_tag(key, options_for_select(options_for_qa_select(key)), class: 'form-select', include_blank: true)
    end

    def search_fields
      blacklight_config.search_fields.select { |_k, v| v.include_in_advanced_search || v.include_in_advanced_search.nil? }
    end

    def sort_fields
      blacklight_config.sort_fields.select { |_k, v| v.include_in_advanced_search || v.include_in_advanced_search.nil? }
    end

    def initialize_primary_search_field_controls
      primary_search_fields_for(search_fields).values.each.with_index do |field, i|
        with_primary_search_field_control do
          get_field_controls(field, i)
        end
      end
    end

    def initialize_secondary_search_field_controls
      secondary_search_fields_for(search_fields).values.each.with_index do |field, i|
        with_secondary_search_field_control do
          get_field_controls(field, i)
        end
      end
    end

    def get_field_controls(field, i)
      fields_for('clause[]', i, include_id: false) do |f|
        content_tag(:div, class: 'form-group advanced-search-field row') do
          f.label(:query, field.display_label('search'), class: "col-sm-3 col-form-label text-md-right") + content_tag(:div, class: 'col-sm-9') do
            if local_authority?(field.key)
              f.hidden_field(:field, value: field.key) + qa_options(field.key)
            else
              f.hidden_field(:field, value: field.key) +
                f.text_field(:query, value: query_for_search_clause(field.key), class: 'form-control')
            end
          end
        end
      end
    end

    def initialize_search_filter_controls
      fields = blacklight_config.facet_fields.select { |_k, v| v.include_in_advanced_search || v.include_in_advanced_search.nil? }

      fields.each do |_k, config|
        display_facet = @response.aggregations[config.field]
        with_search_filter_control(config: config, display_facet: display_facet)
      end
    end

    def initialize_constraints
      params = helpers.search_state.params_for_search.except :page, :f_inclusive, :q, :search_field, :op, :index, :sort

      adv_search_context = helpers.search_state.reset(params)

      constraints_text = render(Blacklight::ConstraintsComponent.for_search_history(search_state: adv_search_context))

      return if constraints_text.blank?

      with_constraint do
        constraints_text
      end
    end

    def query_for_search_clause(key)
      field = (@params[:clause] || {}).values.find { |value| value['field'].to_s == key.to_s }

      field&.dig('query')
    end

    # Determines if the provided key represents a local authority.
    #
    # @param key [String] the key to be checked
    # @return [Boolean] true if the key or its pluralized form is found in the local authorities list; false otherwise
    def local_authority?(key)
      local_qa_names = Qa::Authorities::Local.names
      local_qa_names.include?(key.pluralize) || local_qa_names.include?(key)
    end

    # Gets the options for a QA select based on a given key.
    #
    # @param key [String] the key used to fetch the service and retrieve options
    # @return [Array, nil] the options available for the select, or nil if the service does not provide any options
    def options_for_qa_select(key)
      service = fetch_service_for(key)
      service.try(:select_all_options) || service.try(:select_options) || service.new.select_all_options
    end

    # override blacklight_advanced_search to show only first 4 fields
    def primary_search_fields_for(search_fields)
      search_fields.to_a.first(NUMBER_OF_PRIMARY_FIELDS).to_h
    end

    # override blacklight_advanced_search to show only first 4 fields
    def secondary_search_fields_for(search_fields)
      search_fields.to_a.drop(NUMBER_OF_PRIMARY_FIELDS).to_h
    end

    # Fetches the service for a given key.
    #
    # @param key [String] the key used to determine the service name
    # @return [Class, nil] the service class based on the key, or nil if it does not exist
    def fetch_service_for(key)
      "#{key.camelize}Service".safe_constantize || "#{key.pluralize.camelize}Service".safe_constantize
    end
  end
end
