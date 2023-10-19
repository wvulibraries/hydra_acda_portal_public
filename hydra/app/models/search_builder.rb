# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  self.default_processor_chain += [:add_advanced_parse_q_to_solr, :add_advanced_search_to_solr]

  # Custom Processing of Holt only Records 
  # self.default_processor_chain += [:show_only_acda_records]

  # looks for the project identifier and sets it to holt only 
  # helps to establish that only holt records will be coming form fedora and solr 
  # def show_only_acda_records (solr_parameters)
  #   solr_parameters[:fq] ||= []
  #   solr_parameters[:fq] << 'project_sim:acda'
  # end


  ## DOCUMENTATION OF CUSTOM SOLR CHAIN
  # =====================================================================
  # @example Adding a new step to the processor chain
  #   self.default_processor_chain += [:add_custom_data_to_query]
  #
  #   def add_custom_data_to_query(solr_parameters)
  #     solr_parameters[:custom] = blacklight_params[:user_value]
  #   end
end
