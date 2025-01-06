# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

# Blacklight controller that handles searches and document requests
class CatalogController < ApplicationController

  include BlacklightRangeLimit::ControllerOverride
  include BlacklightAdvancedSearch::Controller

  include Hydra::Catalog
  include BlacklightOaiProvider::Controller
  # This filter applies the hydra access controls
  # before_action :enforce_show_permissions, only: :show

  configure_blacklight do |config|
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:enabled] = true
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'dismax'
    config.advanced_search[:form_solr_parameters] ||= {}

    config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)

    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)
    # add config for exporting as csv
    config.add_results_collection_tool(:export_search_results)

    config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    config.add_show_tools_partial(:citation)

    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository

    ## OAIPMH
    config.oai = {
      provider: {
        repository_name: 'American Congress Digital Archives Portal',
        repository_url: 'https://congressarchivesdev.lib.wvu.edu/catalog/oai',
        record_prefix: 'https://congressarchivesdev.lib.wvu.edu/catalog/',
        admin_email: 'libsys@mail.wvu.edu'
      },
      document: {
        limit: 25,
        set_fields: [
          { label: 'language', solr_field: 'language_facet' }
        ]
      }
    }

    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    config.search_builder_class = ::SearchBuilder

    # Turn off SMS, Email, Citation
    config.show.document_actions.delete(:sms)
    config.show.document_actions.delete(:citation)
    config.show.document_actions.delete(:email)

    # search config
    config.index.title_field = 'title_tesim'
    config.index.display_type_field = 'has_model_ssim'
    config.index.partials = %i[index_header index] # remove default rendering of thumbnail because we want it in a different location
    config.index.thumbnail_method = :render_thumbnail # see ApplicationHelper#render_thumbnail
    config.index.search_bar_component = Wvu::SearchBarComponent

    # QF Builder
    config.default_solr_params = {
      qf: 'identifier_tesim date_tesim contributing_institution_tesim policy_area_tesim names_tesim topic_tesim congress_tesim physical_location_ssi location_represented_tesim type_tesim rights_tesim language_tesim extent_tesim',
      qt: 'search',
      rows: 10,
      facet: true
    }

    # facet creator
    # Facets ---------------------------------------------
    # Organized alphabetically - the ordering of the field names is the order of the display
    config.add_facet_field solr_name('collection_title', :facetable), label: 'Collection', link_to_search: :collection_title_ssi, limit: true, show: true, component: true
    config.add_facet_field solr_name('congress', :facetable), label: 'Congress', link_to_search: :coverage_congress_ssi, limit: true, show: true, component: true
    config.add_facet_field solr_name('contributing_institution', :facetable), label: 'Contributing Institution', link_to_search: :contributing_institution_ssi, limit: true, show: true, component: true
    config.add_facet_field solr_name('creator', :facetable), label: 'Creator', limit: true, show: true, component: true
    config.add_facet_field 'date_ssi', label: 'Date', limit: true, show: true, range: {
      num_segments: 10,
      assumed_boundaries: [1100, Time.now.year + 2],
      segments: false,
      slider_js: false,
      maxlength: 4
    }
    config.add_facet_field solr_name('extent', :facetable), label: 'Extent', limit: true, show: true, component: true
    config.add_facet_field solr_name('language', :facetable), label: 'Language', limit: true, show: true, component: true
    config.add_facet_field solr_name('location_represented', :facetable), label: 'Location Represented', link_to_search: :coverage_spatial_ssi, limit: true, show: true, component: true
    config.add_facet_field solr_name('names', :facetable), label: 'Names', link_to_search: :names_ssi, limit: true, show: true, component: true
    config.add_facet_field solr_name('physical_location', :facetable), label: 'Physical Location', link_to_search: :physical_location_ssi, limit: true, show: true, component: true
    config.add_facet_field solr_name('policy_area', :facetable), label: 'Policy Area', link_to_search: :policy_area_ssi, limit: true, show: true, component: true
    config.add_facet_field solr_name('publisher', :facetable), label: 'Publisher', link_to_search: :publisher_ssi, limit: true, show: true, component: true
    config.add_facet_field solr_name('record_type', :facetable), label: 'Record Type', limit: true, show: true, component: true
    config.add_facet_field solr_name('rights', :facetable), label: 'Rights', limit: true, show: true, component: true
    config.add_facet_field solr_name('topic', :facetable), label: 'Topic', link_to_search: :topic_ssi, limit: true, show: true, component: true

    # uses the above facets in blacklight
    #config.default_solr_params['facet.field'] = config.facet_fields.keys
    config.add_facet_fields_to_solr_request!

    # Index ---------------------------------------------
    # The ordering of the field names is the order of the display
    config.add_index_field solr_name('identifier', :stored_searchable), label: 'Identifier'
    config.add_index_field solr_name('contributing_institution', :stored_searchable, type: :string), label: 'Contributing Institution', helper_method: :render_html_safe_url
    config.add_index_field solr_name('collection_title', :stored_searchable), label: 'Collection', helper_method: :render_html_safe_url
    config.add_index_field solr_name('title', :stored_searchable, type: :string), label: 'Title'
    config.add_index_field solr_name('date', :stored_searchable, type: :string), label: 'Date', helper_method: :render_html_safe_url
    config.add_index_field solr_name('creator', :stored_searchable, type: :string), label: 'Creator', helper_method: :render_html_safe_url
    config.add_index_field solr_name('publisher', :stored_searchable, type: :string), label: 'Publisher', helper_method: :render_html_safe_url
    config.add_index_field solr_name('policy_area', :stored_searchable, type: :string), label: 'Policy Area', helper_method: :render_html_safe_url
    config.add_index_field solr_name('names', :stored_searchable), label: 'Names', helper_method: :render_html_safe_url
    config.add_index_field solr_name('topic', :stored_searchable, type: :string), label: 'Topic', helper_method: :render_html_safe_url
    config.add_index_field solr_name('congress', :stored_searchable, type: :string), label: 'Congress', helper_method: :render_html_safe_url
    config.add_index_field solr_name('location_respresented', :stored_searchable, type: :string), label: 'Location Respresented', helper_method: :render_html_safe_url

    # Show ---------------------------------------------
    # show fields in the objects
    # order is by the order you put them in
    config.add_show_field solr_name('identifier', :stored_searchable, type: :string), label: 'Identifier'
    config.add_show_field solr_name('contributing_institution', :stored_searchable, type: :string), label: 'Contributing Institution', link_to_search: :contributing_institution_sim
    config.add_show_field solr_name('title', :stored_searchable, type: :string), label: 'Title'
    config.add_show_field solr_name('date', :stored_searchable, type: :string), label: 'Date Created', link_to_search: :date_sim
    config.add_show_field solr_name('edtf', :stored_searchable, type: :string), label: 'EDTF'
    config.add_show_field solr_name('creator', :stored_searchable, type: :string), label: 'Creator', link_to_search: :creator_sim
    config.add_show_field solr_name('rights', :stored_searchable, type: :string), label: 'Rights', helper_method: :render_html_safe_url
    config.add_show_field solr_name('language', :stored_searchable, type: :string), label: 'Language'
    config.add_show_field solr_name('record_type', :stored_searchable, type: :string), label: 'Record Type'
    config.add_show_field solr_name('collection_title', :stored_searchable, type: :string), label: 'Collection', link_to_search: :collection_title_sim
    config.add_show_field solr_name('collection_finding_aid', type: :string), label: 'Collection Finding Aid', helper_method: :render_html_safe_url
    config.add_show_field solr_name('description', :stored_searchable, type: :string), label: 'Description'
    config.add_show_field solr_name('policy_area', :stored_searchable, type: :string), label: 'Policy Area', link_to_search: :policy_area_sim
    config.add_show_field solr_name('names', :stored_searchable, type: :string), label: 'Names', link_to_search: :names_sim
    config.add_show_field solr_name('topic', :stored_searchable, type: :string), label: 'Topic', link_to_search: :topic_sim
    config.add_show_field solr_name('congress', :stored_searchable, type: :string), label: 'Congress', link_to_search: :congress_sim
    config.add_show_field solr_name('physical_location', :stored_searchable, type: :string), label: 'Physical Location', link_to_search: :physical_location_ssi
    config.add_show_field solr_name('location_represented', :stored_searchable, type: :string), label: 'Location Represented', link_to_search: :location_represented_sim
    config.add_show_field solr_name('dc_type', :stored_searchable, type: :string), label: 'Type'
    config.add_show_field solr_name('extent', :stored_searchable, type: :string), label: 'Extent'
    config.add_show_field solr_name('publisher', :stored_searchable, type: :string), label: 'Publisher', link_to_search: :publisher_sim

    # search fields
    config.add_search_field('all_fields', label: 'All Fields') do |field|
      all_names = config.show_fields.values.map(&:field).join(" ")
      title_name = 'title_tesim'
      field.solr_parameters = {
        qf: "#{all_names}",
        pf: title_name.to_s
      }
    end

    # add the search fields individually from solr
    # use this as a template for creating new ones
    # Search ---------------------------------------------
    default_search_fields = %w[
      creator
      date
      names
      title
      collection_title
      congress
      contributing_institution
      description
      identifier
      language
      location_represented
      policy_area
      publisher
      record_type
      rights
      topic
    ]
    default_search_fields.map! { |f|
      config.add_search_field(f.to_s) do |field|
          field.solr_parameters = {
           qf: solr_name(f.to_s, :stored_searchable, type: :string),
           pf: solr_name(f.to_s, :stored_searchable, type: :string)
          }
       end
    }

    # sorting results should be custom to each collection
    sort_date = Solrizer.solr_name('date', :stored_sortable, type: :string)
    sort_title = Solrizer.solr_name('title', :stored_sortable, type: :string)
    sort_creator = Solrizer.solr_name('creator', :stored_sortable, type: :string)
    sort_identifier = Solrizer.solr_name('identifier', :stored_sortable, type: :string)

    config.add_sort_field "#{sort_date} asc", :label => 'Date (asc)'
    config.add_sort_field "#{sort_date} desc", :label => 'Date (desc)'
    config.add_sort_field "#{sort_identifier} asc", :label => 'Identifier (asc)'
    config.add_sort_field "#{sort_identifier} desc", :label => 'Identifier (desc)'
    config.add_sort_field "#{sort_title} asc", :label => 'Title (A-Z)'
    config.add_sort_field "#{sort_title} desc", :label => 'Title (Z-A)'
    config.add_sort_field "#{sort_creator} asc", :label => 'Creator (A-Z)'
    config.add_sort_field "#{sort_creator} desc", :label => 'Creator (Z-A)'
    config.add_sort_field "score desc, #{sort_identifier} asc", :label => 'Relevance'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    config.fetch_many_document_params = { fl: "*" }
  end

  def index
    return super if params[:range].nil?

    start_date = params[:range]["date_ssi"]["begin"]
    end_date = params[:range]["date_ssi"]["end"]

    if start_date.present? && end_date.present? && (start_date.to_i > end_date.to_i)
      flash[:error] = "The min date must be before the max date"
      redirect_to request.referrer
      return
    end

    super
  end

  # def show
  #   super
  #   @metadata = []
  #   # loop over each field and add it to the metadata
  #   @document.each_pair do |k,v|
  #     @metadata << [k, v] unless v.present?
  #   end
  # end

  def export
    @response = search_service.search_results[0]

    respond_to do |format|
      format.csv {
        send_data ExportResultsPresenter.new(@response).to_csv, layout: false, filename: "search-results-#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')}.csv"
      }

      format.xml {
        send_data ExportResultsPresenter.new(@response).to_xml, layout: false, filename: "search-results-#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')}.xml"
      }
    end
  end
end
