# Generated Model for Metadata
require 'net/http'
require 'uri'

class Acda < ActiveFedora::Base
  include Hydra::AccessControls::Permissions

  include ImportLibrary
  include ApplicationHelper

  before_save :format_urls
  after_save :clear_empty_fields_and_generate_thumbnail

  def clear_empty_fields_and_generate_thumbnail
    clear_empty_fields
    generate_or_download_thumbnail if saved_change_to_available_by? || saved_change_to_preview?
  end

  def saved_change_to_preview?
    previous_changes['preview'].present?
  end

  def saved_change_to_available_by?
    previous_changes['available_by'].present? || thumbnail_file.blank?
  end

  def format_urls
    # insure all urls are formatted correctly
    self.available_at = format_url(self.available_at)
    self.preview = update_preview if self.preview.blank?
    self.preview = format_url(self.preview)
    self.available_by = format_url(self.available_by)
  end

  self.indexer = ::Indexer

  def update_preview
    # check if preview is blank
    if self.preview.blank?
      # lets try to find the preview (thumbnail) from available_at
      self.preview = generate_preview

      # if preview is still blank, return
      return if self.preview.blank?
    end

    # resolve redirect for preview
    updated_preview = resolve_redirect(self.preview)

    # update preview if it has changed
    self.preview = updated_preview if updated_preview != preview 
  end

  def generate_preview
    # check and see if available_at is a preservica.com address
    if available_at.include?('preservica.com')
      # add download/thumbnail/ after the preservica.com to the url
      preservica_url = available_at.gsub('preservica.com', 'preservica.com/download/thumbnail')
      # return the new url
      return preservica_url
    end
  end

  def generate_or_download_thumbnail 
    if preview.present?
      # queue job to download and set the thumbnail
      # using the available_at url
      DownloadAndSetThumbsJob.perform_later(id)
    else
      # queue job to generate thumbnail
      GenerateThumbsJob.perform_later(id)
    end
  end

  def clear_empty_fields
    # temporary fix for bulkrax import setting some empty strings into the Relation
    # reported issue to on slack on 6-20-2023 tam0013@mail.wvu.edu

    # get keys
    keys = self.attributes.keys
    # loop over keys skipping id and visibility fields
    keys.each do |key|
      # skip id
      next if key == 'id' || key == 'visibility'
      # if class is a relation and has only one element and that element is blank
      if self[key].class == ActiveTriples::Relation && self[key].to_a.count == 1
        # convert to array
        temp_array = self[key].to_a
        # delete first element if it is blank
        if temp_array.to_a.first == ""
          temp_array.delete_at(0)
          # set array back to relation
          self[key] = temp_array
        end
      end
    end
  end

  # Minting ID
  # Overriding Fedoras LONG URI NOT FRIENDLY ID
  def assign_id
    # Ensure identifier is defined or fetched
    identifier = self.identifier if self.respond_to?(:identifier)

    # Removes the protocol (http or https) and domain part of the url
    cleaned_identifier = identifier.gsub(/https?:\/\/[^\/]+\//, '')

    # Removes special characters typically found in urls
    cleaned_identifier = cleaned_identifier.gsub(/[\/:?%&=#+_]/, '_')

    # Replaces periods with empty strings to maintain the original functionality
    cleaned_identifier.gsub('.', '').to_s
  end

  # DC provenance
  # ==============================================================================================================
  # contributing institution property
  property :contributing_institution, predicate: ::RDF::Vocab::DC.provenance, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC Title
  # ==============================================================================================================
  # title property
  property :title, predicate: ::RDF::Vocab::DC.title, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC date
  # ==============================================================================================================
  # date property
  property :date, predicate: ::RDF::Vocab::DC.date, multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC format
  # ==============================================================================================================
  # edtf property
  # not shown in the UI
  property :edtf, predicate: ::RDF::Vocab::DC.created, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC creator
  # ==============================================================================================================
  # creator property
  property :creator, predicate: ::RDF::Vocab::DC.creator, multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC rights
  # ==============================================================================================================
  # rights property
  property :rights, predicate: ::RDF::Vocab::DC.rights, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC language
  # ==============================================================================================================
  # language property
  property :language, predicate: ::RDF::Vocab::DC.language, multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC temporal
  # ==============================================================================================================
  # congress property
  property :congress, predicate: ::RDF::Vocab::DC.temporal, multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC relation
  # ==============================================================================================================
  # collection property
  property :collection_title, predicate: ::RDF::Vocab::DC.relation, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC isPartOf
  # ==============================================================================================================
  # physical location property
  property :physical_location, predicate: ::RDF::Vocab::DC.isPartOf, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC source
  # ==============================================================================================================
  # collection finding aid property
  property :collection_finding_aid, predicate: ::RDF::Vocab::DC.source, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC identifier
  # ==============================================================================================================
  # identifier property
  property :identifier, predicate: ::RDF::Vocab::DC.identifier, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # EDM preview - (link to external thumbnail image)
  # ==============================================================================================================
  # preview property
  property :preview, predicate: ::RDF::Vocab::EDM.preview, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # EDM isShownAt - (link to external resource)
  # ==============================================================================================================
  # Avaliable At Property
  property :available_at, predicate: ::RDF::Vocab::EDM.isShownAt, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # EDM isShownBy - Direct PDF or Image URI (to download)
  # ==============================================================================================================
  # Avaliable By Property
  property :available_by, predicate: ::RDF::Vocab::EDM.isShownBy, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC record type
  # ==============================================================================================================
  # Record Type property
  property :record_type, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/recordType'), multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC subject
  # ==============================================================================================================
  # Policy Area property
  property :policy_area, predicate: ::RDF::Vocab::DC.subject, multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # Internal predicate of Subject
  # ==============================================================================================================
  # Topic property
  property :topic, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/subject'), multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC contributor
  # ==============================================================================================================
  # Names property
  property :names, predicate: ::RDF::Vocab::DC.contributor, multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC spatial
  # ==============================================================================================================
  # Location Represented property
  property :location_represented, predicate: ::RDF::Vocab::DC.spatial, multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC format
  # ==============================================================================================================
  # type extent
  property :extent, predicate: ::RDF::Vocab::DC.format, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC publisher
  # ==============================================================================================================
  # publisher property
  property :publisher, predicate: ::RDF::Vocab::DC.publisher, multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC description
  # ==============================================================================================================
  # description property
  property :description, predicate: ::RDF::Vocab::DC.description, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # DC type
  # This not to be confused with record type this is required to identify the type of record Sound, Image, Text, etc.
  # So we can render the correct viewer
  # ==============================================================================================================
  # type dc_type
  property :dc_type, predicate: ::RDF::Vocab::DC.type, multiple: false do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
  end

  # PROJECT IDENTIFIER
  # ==============================================================================================================
  # used in the search builder to target only records from this collection
  property :project, predicate: ::RDF::URI.intern('http://lib.wvu.edu/hydra/project'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  # PROJECT IDENTIFIER
  # ==============================================================================================================
  property :bulkrax_identifier, predicate: ::RDF::URI("https://hykucommons.org/terms/bulkrax_identifier"), multiple: false do |index|
    index.as :stored_searchable
  end

  directly_contains :files, has_member_relation: ::RDF::URI('http://pcdm.org/models#File'), class_name: 'AcdaFile'

  # image property
  directly_contains_one :image_file, through: :files, type: ::RDF::URI('http://pcdm.org/file-format-types#Image'),
                                     class_name: 'AcdaFile'

  # thumbnail property
  directly_contains_one :thumbnail_file, through: :files, type: ::RDF::URI('http://pcdm.org/use#ThumbnailImage'),
                                         class_name: 'AcdaFile'

  # pdf property
  directly_contains_one :pdf_file, through: :files, type: ::RDF::URI('http://pcdm.org/file-format-types#Document'),
                                   class_name: 'AcdaFile'

  # audio property
  directly_contains_one :audio_file, through: :files, type: ::RDF::URI('http://pcdm.org/file-format-types#Audio'),
                                     class_name: 'AcdaFile'

  # video property
  directly_contains_one :video_file, through: :files, type: ::RDF::URI('http://pcdm.org/file-format-types#Video'),
                                     class_name: 'AcdaFile'
end
