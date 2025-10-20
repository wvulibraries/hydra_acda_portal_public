# Generated Model for Metadata
require 'net/http'
require 'uri'

class Acda < ActiveFedora::Base
  include Hydra::AccessControls::Permissions

  include ImportLibrary
  include ApplicationHelper
  include ThumbnailProcessable

  before_create :prepare_record
  after_save :handle_thumbnail_generation, unless: :skip_thumbnail_update
  attr_accessor :skip_thumbnail_update

  def prepare_record
    format_urls
    clear_empty_fields
  end

  def saved_change_to_preview?
    previous_changes['preview'].present?
  end

  def saved_change_to_available_by?
    previous_changes['available_by'].present?
  end

  def saved_change_to_available_at?
    previous_changes['available_at'].present?
  end

  def format_urls
    Rails.logger.debug "Formatting URLs for #{id}:"
    Rails.logger.debug "  Before - preview: #{preview}, available_at: #{available_at}, available_by: #{available_by}"
    
    # Format basic URLs
    self.available_at = format_url(self.available_at)
    self.available_by = format_url(self.available_by)
    
    # Handle preview URL
    if self.preview.blank?
      # For Hawaii records - use available_by as source for preview
      url = self.available_by || self.available_at
      self.preview = format_url(generate_preview(url))
    else
      # For RBL records - use existing preview URL
      self.preview = format_url(self.preview)
    end

    # Check for redirects
    updated_preview = resolve_redirect(self.preview)
    self.preview = updated_preview if updated_preview != preview
    
    Rails.logger.debug "  After - preview: #{preview}, available_at: #{available_at}, available_by: #{available_by}"
  end

  self.indexer = ::Indexer

  def generate_preview(url)
    return nil if url.blank?

    url_down = url.downcase

    if url_down.include?('preservica.com')
      # Only transform Preservica URLs
      url.gsub('preservica.com', 'preservica.com/download/thumbnail')
    elsif url_down.include?('/download') || url_down.include?('/content') || url_down.end_with?('.pdf')
      # For downloadable content that needs thumbnail generation
      nil
    else
      # For all other URLs, return as-is
      url
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
      value = self[key]

      # Only process ActiveTriples::Relation (or similar array-like) values
      if value.is_a?(ActiveTriples::Relation)
        # Convert to array and reject blank values
        cleaned_values = value.to_a.reject(&:blank?)

        # If all were blank, it becomes []
        self[key] = cleaned_values
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

  # Queued Job
  # ==============================================================================================================
  # field to manage processing of queued jobs
  property :queued_job, predicate: ::RDF::URI.new('http://acda.lib.wvu.edu/ns#queued_job'), multiple: false

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
  property :topic, predicate: ::RDF::URI.intern('dcterms:http://purl.org/dc/elements/1.1/subject'), multiple: true do |index|
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

  def self.queue_pending_thumbnails
    where(queued_job: nil).find_each(batch_size: 1) do |record|
      next unless record.preview.present?
      begin
        record.queued_job = 'true'
        record.save_with_retry!(validate: false)
        DownloadAndSetThumbsJob.set(wait: 2.seconds).perform_later(record.id)
      rescue Ldp::Conflict => e
        Rails.logger.error "LDP Conflict for #{record.id}: #{e.message}"
        retry_count = 0
        begin
          retry_count += 1
          sleep(rand(1..3))  # Increased backoff
          retry if retry_count < 3
        end
      end
    end
  end

  # Modified thumbnail generation method in Acda model
  def handle_thumbnail_generation
    return if queued_job.present? && ['true', 'completed'].include?(queued_job)
    return unless needs_thumbnail_update?
    
    # Prevent callbacks from triggering during thumbnail generation
    self.skip_thumbnail_update = true
    
    # Queue a single job type regardless of content type
    ProcessThumbnailJob.perform_once(id)
    Rails.logger.info "Queued ProcessThumbnailJob for #{id}"
  end

  def needs_thumbnail_update?
    return true if image_file.blank? && thumbnail_file.blank?
    return true if saved_change_to_preview? || saved_change_to_available_by? || saved_change_to_available_at?
    false
  end

  def save_with_retry!(opts = {})
    retries = 0
    max_retries = 3
    begin
      if opts[:validate] == false
        save!(validate: false)
      else
        save!
      end
    rescue Ldp::Conflict => e
      retries += 1
      if retries < max_retries
        Rails.logger.info "Retrying save after LDP conflict for #{id} (attempt #{retries})"
        sleep(1 + retries)  # Progressive backoff
        retry
      else
        Rails.logger.error "Failed to save after #{retries} attempts for #{id}"
        raise
      end
    end
  end

  # Add to Acda model
  def self.with_lock(id)
    transaction do
      record = find(id)
      record.lock!  # Acquire a database lock
      yield record
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Record #{id} not found for locking"
    false
  end

  # Add to Acda model
  def self.with_thumbnail_lock(id)
    record = find(id)
    return false if record.queued_job == 'true' # Already being processed
    
    # Set a lock
    record.queued_job = 'true'
    record.save_with_retry!(validate: false)
    
    begin
      # Run the provided block
      yield record
      # Mark as completed
      record.queued_job = 'completed'
      record.save_with_retry!(validate: false)
      return true
    rescue => e
      # On failure, still mark as completed to prevent infinite retries
      record.queued_job = 'completed' 
      record.save_with_retry!(validate: false)
      Rails.logger.error "Error in thumbnail processing: #{e.message}"
      return false
    end
  end
end
