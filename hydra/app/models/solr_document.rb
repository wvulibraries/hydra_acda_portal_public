# frozen_string_literal: true

# Represents a single document returned from Solr
class SolrDocument
  include Blacklight::Solr::Document
  include BlacklightOaiProvider::SolrDocument
  use_extension Blacklight::Document::DublinCore

  ACDA_URL = 'http://congressarchivesdev.lib.wvu.edu/record/'

  def to_semantic_values
    @semantic_value_hash ||= self.class.field_semantics.each_with_object(Hash.new([])) do |(key, field_names), hash|
      value = Array.wrap(field_names).map { |field_name| self[field_name] }.flatten.compact
      hash[key] = value unless value.empty?
    end

    @semantic_value_hash ||= {}
    idno = @semantic_value_hash[:identifier].first

    # Check if the identifier is a URL
    if url?(idno)
      # accounts for something like http://hdl.handle.net/123/123 being the identifier
      # we wouldn't want to prepend our URL in that case
      @semantic_value_hash[:identifier] = idno
    else
      @semantic_value_hash[:identifier] = ACDA_URL + idno
    end

    @semantic_value_hash
  end

  field_semantics.merge!(
    contributing_institution: 'contributing_institution_tesim',
    title: 'title_tesim',
    date: 'date_tesim',
    edtf: 'edtf_tesim',
    creator: 'creator_tesim',
    rights: 'rights_tesim',
    language: 'language_tesim',
    congress: 'congress_tesim',
    collection_title: 'collection_title_tesim',
    physical_location: 'physical_location_tesim',
    collection_finding_aid: 'collection_finding_aid_tesim',
    identifier: 'identifier_tesim',
    preview: 'preview_tesim',
    available_at: 'available_at_tesim',
    available_by: 'available_by_tesim',
    record_type: 'record_type_tesim',
    policy_area: 'policy_area_tesim',
    topic: 'topic_tesim',
    names: 'names_tesim',
    location_represented: 'slocation_represented_tesim',
    extent: 'extent_tesim',
    publisher: 'publisher_tesim',
    description: 'description_tesim',
    dc_type: 'dc_type_tesim',
    project: 'project_tesim',
    bulkrax_identifier: 'bulkrax_identifier_tesim'
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

  def image_file?
    self['has_image_file_bsi']
  end

  def thumbnail_file?
    self['has_thumbnail_file_bsi']
  end

  private

    # Check if a given string is a URL
    def url?(str)
      str =~ /\A#{URI::DEFAULT_PARSER.make_regexp(['http', 'https'])}\z/
    end
end