# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController

  include Hydra::Catalog
  include BlacklightOaiProvider::Controller
  # This filter applies the hydra access controls
  # before_action :enforce_show_permissions, only: :show

  configure_blacklight do |config|
    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository

    ## OAIPMH
    config.oai = {
      provider: {
        repository_name: 'American Congress Digital Archives Portal',
        repository_url: 'https://acda.lib.wvu.edu/catalog/oai',
        record_prefix: 'https://acda.lib.wvu.edu/catalog/',
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

    # QF Builder
    config.default_solr_params = {
      qf: 'identifier_tei date_tesim contributing_institution_tesim subject_policy_tesim subject_names_tesim subject_topical_tesim coverage_congress_tesim coverage_spatial_tesim type_tesim rights_tesim language_tesim extent_tesim',
      qt: 'search',
      rows: 10,
      facet: true
    }

    # facet creator
    # Facets ---------------------------------------------
    config.add_facet_field solr_name('date', :facetable), label: 'Date', limit: true, show: true, component: true
    config.add_facet_field solr_name('creator', :facetable), label: 'Creator', limit: true, show: true, component: true
    config.add_facet_field solr_name('contributing_institution', :facetable), label: 'Contributing Institution', link_to_search: :contributing_institution_ssi, limit: true, show: true, component: true
    config.add_facet_field solr_name('collection', :facetable), label: 'Collection', link_to_search: :collection_ssi, limit: true, show: true, component: true
    config.add_facet_field solr_name('publisher', :facetable), label: 'Publisher', link_to_search: :publisher_ssi, limit: true, show: true, component: true
    config.add_facet_field solr_name('subject_policy', :facetable), label: 'Subject Policy', link_to_search: :subject_policy_ssi, limit: true, show: true, component: true
    config.add_facet_field solr_name('subject_names', :facetable), label: 'Subject Names', link_to_search: :subject_names_ssi, limit: true, show: true, component: true    
    config.add_facet_field solr_name('subject_topical', :facetable), label: 'Subject Topical', link_to_search: :subject_topical_ssi, limit: true, show: true, component: true
    config.add_facet_field solr_name('coverage_congress', :facetable), label: 'Coverage Congress', link_to_search: :coverage_congress_ssi, limit: true, show: true, component: true
    config.add_facet_field solr_name('coverage_spatial', :facetable), label: 'Coverage Spatial', link_to_search: :coverage_spatial_ssi, limit: true, show: true, component: true
    config.add_facet_field solr_name('type', :facetable), label: 'Type', limit: true, show: true, component: true
    config.add_facet_field solr_name('rights', :facetable), label: 'Rights', limit: true, show: true, component: true
    config.add_facet_field solr_name('language', :facetable), label: 'Language', limit: true, show: true, component: true
    config.add_facet_field solr_name('extent', :facetable), label: 'Extent', limit: true, show: true, component: true

    # uses the above facets in blacklight
    #config.default_solr_params['facet.field'] = config.facet_fields.keys
    config.add_facet_fields_to_solr_request!
    
    # Index ---------------------------------------------
    # The ordering of the field names is the order of the display
    config.add_index_field solr_name('identifier', :stored_searchable), label: 'Identifier'     
    config.add_index_field solr_name('alternate_identifier', :stored_searchable, type: :string), label: 'Alternate Identifier'
    config.add_index_field solr_name('contributing_institution', :stored_searchable, type: :string), label: 'Contributing Institution', link_to_search: :contributing_institution_sim
    config.add_index_field solr_name('collection', :stored_searchable), label: 'Collection', link_to_search: :collection_sim
    config.add_index_field solr_name('title', :stored_searchable, type: :string), label: 'Title'
    config.add_index_field solr_name('date', :stored_searchable, type: :string), label: 'Date', link_to_search: :date_sim
    config.add_index_field solr_name('creator', :stored_searchable, type: :string), label: 'Creator', link_to_search: :creator_sim
    config.add_index_field solr_name('publisher', :stored_searchable, type: :string), label: 'Publisher', link_to_search: :publisher_sim
    config.add_index_field solr_name('subject_policy', :stored_searchable, type: :string), label: 'Subject Policy', link_to_search: :subject_policy_sim
    config.add_index_field solr_name('subject_names', :stored_searchable), label: 'Subject Names', link_to_search: :subject_names_sim
    config.add_index_field solr_name('subject_topical', :stored_searchable, type: :string), label: 'Subject Topical', link_to_search: :subject_topical_sim
    config.add_index_field solr_name('coverage_congress', :stored_searchable, type: :string), label: 'Coverage Congress', link_to_search: :coverage_congress_sim
    config.add_index_field solr_name('coverage_spatial', :stored_searchable, type: :string), label: 'Coverage Spatial', link_to_search: :coverage_spatial_sim

    # Show ---------------------------------------------
    # show fields in the objects 
    # order is by the order you put them in 
    config.add_show_field solr_name('identifier', :stored_searchable, type: :string), label: 'Identifier'  
    config.add_show_field solr_name('contributing_institution', :stored_searchable, type: :string), label: 'Contributing Institution', link_to_search: :contributing_institution_sim
    config.add_show_field solr_name('title', :stored_searchable, type: :string), label: 'Title'
    config.add_show_field solr_name('date', :stored_searchable, type: :string), label: 'Date Created', link_to_search: :date_sim
    config.add_show_field solr_name('edtf', :stored_searchable, type: :string), label: 'EDTF'
    config.add_show_field solr_name('creator', :stored_searchable, type: :string), label: 'Creator', link_to_search: :creator_sim
    config.add_show_field solr_name('rights', :stored_searchable, type: :string), label: 'Rights Statement'
    config.add_show_field solr_name('rights2', :stored_searchable, type: :string), label: 'Rights'
    config.add_show_field solr_name('alternate_identifier', :stored_searchable, type: :string), label: 'Alternate Identifier'
    config.add_show_field solr_name('language', :stored_searchable, type: :string), label: 'Language'
    config.add_show_field solr_name('record_type', :stored_searchable, type: :string), label: 'Record Type'
    config.add_show_field solr_name('collection', :stored_searchable, type: :string), label: 'Collection', link_to_search: :collection_sim
    config.add_show_field solr_name('collection_finding_aid', type: :string), label: 'Collection Finding Aid', helper_method: :render_html_safe_url
    config.add_show_field solr_name('description', :stored_searchable, type: :string), label: 'Description'
    config.add_show_field solr_name('subject_policy', :stored_searchable, type: :string), label: 'Subject Policy', link_to_search: :subject_policy_sim
    config.add_show_field solr_name('subject_names', :stored_searchable, type: :string), label: 'Subject Names', link_to_search: :subject_names_sim 
    config.add_show_field solr_name('subject_topical', :stored_searchable, type: :string), label: 'Subject Topical', link_to_search: :subject_topical_sim
    config.add_show_field solr_name('coverage_congress', :stored_searchable, type: :string), label: 'Coverage Congress', link_to_search: :coverage_congress_sim
    config.add_show_field solr_name('coverage_spatial', :stored_searchable, type: :string), label: 'Coverage Spatial', link_to_search: :coverage_spatial_sim
    config.add_show_field solr_name('type', :stored_searchable, type: :string), label: 'Type'
    config.add_show_field solr_name('extent', :stored_searchable, type: :string), label: 'Extent'
    config.add_show_field solr_name('publisher', :stored_searchable, type: :string), label: 'Publisher', link_to_search: :publisher_sim
    config.add_show_field solr_name('viaf_ids', :stored_searchable, type: :string), label: "VIAF Id's", link_to_search: :viaf_ids_sim
    config.add_show_field solr_name('full_text', :stored_searchable, type: :string), label: 'Full Text'

    # search fields  
    config.add_search_field 'all_fields', label: 'All Fields'

    # add the search fields individually from solr 
    # use this as a template for creating new ones 
    # Search ---------------------------------------------
    default_search_fields = ['identifier', 'alternate_identifier', 'date', 'contributing_institution', 'subject_policy', 'subject_names', 'subject_topical', 'coverage_congress', 'coverage_spatial', 'type', 'rights', 'language', 'extent']
    default_search_fields.map! { |f| 
      config.add_search_field(f) do |field|
          field.solr_parameters = {
           qf: solr_name(f, :stored_searchable, type: :string),
           pf: solr_name(f, :stored_searchable, type: :string)
          }
       end  
    } 

    # sorting results should be custom to each collection
    sort_title = Solrizer.solr_name('title', :stored_sortable, type: :string)
    sort_creator = Solrizer.solr_name('creator', :stored_sortable, type: :string)
    sort_identifier = Solrizer.solr_name('identifier', :stored_sortable, type: :string)

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

  # adds additional pages that will also use the searchbar from the navigation 
  # customizable behavior should be done in a module or static model 
  def about
    render "about.html.erb"
  end

  def contact
    render "contact.html.erb"
  end

  def partners
    render "partners.html.erb"
  end

  def policies
    render "policies.html.erb"
  end
end
