# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document
  include BlacklightOaiProvider::SolrDocument
  use_extension Blacklight::Document::DublinCore

  def to_semantic_values
    @semantic_value_hash ||= self.class.field_semantics.each_with_object(Hash.new([])) do |(key, field_names), hash|
      value = Array.wrap(field_names).map { |field_name| self[field_name] }.flatten.compact
      hash[key] = value unless value.empty?
    end

    @semantic_value_hash ||= {}
    idno = @semantic_value_hash[:identifier].first
    @semantic_value_hash[:identifier] = "http://acda.lib.wvu.edu/record/#{idno}"
    @semantic_value_hash
  end

  field_semantics.merge!(
    identifier: 'identifier_tesim',
    # item_number: 'item_number_tesim',
    #oclc_number: 'oclc_number_tesim',
    title: 'title_tesim',
    date: 'edtf_tesim',
    creator: 'creator_tesim',
    #contributor: 'contributor_tesim',
    publisher: 'publisher_tesim',
    description: 'description_tesim',
    subject: 'subject_tesim',
    type: 'type_tesim',
    #provenance: 'provenance_dpla_tesim',
    rights: 'rights_tesim',
    #location: 'location_tesim',
    #temporal: 'time_period_tesim',
    #format: 'format_tesim',
    language: 'language_tesim',
    #source: 'source_tesim',
    extent: 'extent_tesim',
    project: 'project_tesim',
    #converage: 'published_location_tesim'
  )

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  # Do content negotiation for AF models. 
  use_extension( Hydra::ContentNegotiation )

  # Sets 
  def sets
    fetch('language', []).map { |l| BlacklightOaiProvider::Set.new("language:#{l}") }
  end
end
