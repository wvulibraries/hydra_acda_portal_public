# ActiveRecord replacement for the ActiveFedora-backed Acda model.
# File attachments, the access_controls association, the permission
# getters/setters + computed visibility, blank-value cleanup on save, and
# ID minting for new records that don't already have one set.
#
# Deliberately NOT included yet (separate, later step):
#   - handle_thumbnail_generation / queue_pending_thumbnails / with_thumbnail_lock
#     (depend on ProcessThumbnailJob/DownloadAndSetThumbsJob, which are
#     still Fedora-specific and need their own adaptation pass)
class CongressionalRecord < ApplicationRecord
  has_one_attached :image_file
  has_one_attached :thumbnail_file
  has_one_attached :pdf_file
  has_one_attached :audio_file
  has_one_attached :video_file

  has_many :access_controls, dependent: :destroy

  before_create :assign_id, unless: :id?
  before_save :clear_empty_fields

  PERMISSION_TEXT_VALUE_PUBLIC = 'public'.freeze
  PERMISSION_TEXT_VALUE_AUTHENTICATED = 'registered'.freeze
  VISIBILITY_TEXT_VALUE_PUBLIC = 'open'.freeze
  VISIBILITY_TEXT_VALUE_AUTHENTICATED = 'authenticated'.freeze
  VISIBILITY_TEXT_VALUE_PRIVATE = 'restricted'.freeze

  # Computed, not stored - mirrors Hydra::AccessControls::Visibility#visibility
  # exactly: derived from whether read_groups contains 'public'/'registered'.
  def visibility
    if read_groups.include?(PERMISSION_TEXT_VALUE_PUBLIC)
      VISIBILITY_TEXT_VALUE_PUBLIC
    elsif read_groups.include?(PERMISSION_TEXT_VALUE_AUTHENTICATED)
      VISIBILITY_TEXT_VALUE_AUTHENTICATED
    else
      VISIBILITY_TEXT_VALUE_PRIVATE
    end
  end

  # discover_groups / discover_users / read_groups / read_users /
  # edit_groups / edit_users - getters and setters, backed by access_controls
  # rows instead of Fedora Permission objects. Mirrors
  # Hydra::AccessControls::Permissions' method names exactly.
  %i[discover read edit].each do |level|
    define_method("#{level}_groups") { agent_names('group', level) }
    define_method("#{level}_users") { agent_names('person', level) }
    define_method("#{level}_groups=") { |names| set_agents('group', level, names) }
    define_method("#{level}_users=") { |names| set_agents('person', level, names) }
  end


  SOLR_SEARCHABLE_SORTABLE_FACETABLE_FIELDS = %i[
    contributing_institution title date edtf creator rights language congress
    collection_title physical_location collection_finding_aid identifier
    preview available_at available_by record_type policy_area topic names
    location_represented extent description dc_type publisher
  ].freeze

  SOLR_SEARCHABLE_FACETABLE_FIELDS = %i[project].freeze
  SOLR_SEARCHABLE_ONLY_FIELDS = %i[bulkrax_identifier].freeze

  # Builds the same Solr document shape that Acda#to_solr (via
  # ActiveFedora::IndexingService + ::Indexer) produces today, so search,
  # facets, sorting, and show pages keep working unchanged once a
  # record's Solr document is built from this table instead of Fedora.
  # See the class comment above for the two deliberate differences
  # (has_model_ssim, accessControl_ssim).
  def to_solr
    doc = {
      'id' => id,
      'system_create_dtsi' => created_at&.utc&.strftime('%Y-%m-%dT%H:%M:%SZ'),
      'system_modified_dtsi' => updated_at&.utc&.strftime('%Y-%m-%dT%H:%M:%SZ'),
      'has_model_ssim' => ['Acda'],
      'has_image_file_bsi' => image_file.attached?,
      'has_thumbnail_file_bsi' => thumbnail_file.attached?
    }

    SOLR_SEARCHABLE_SORTABLE_FACETABLE_FIELDS.each { |f| index_text_field(doc, f, sortable: true, facetable: true) }
    SOLR_SEARCHABLE_FACETABLE_FIELDS.each { |f| index_text_field(doc, f, sortable: false, facetable: true) }
    SOLR_SEARCHABLE_ONLY_FIELDS.each { |f| index_text_field(doc, f, sortable: false, facetable: false) }

    if edtf.present? && EDTF.parse(edtf)
      parsed_date = Date.edtf!(edtf.downcase)
      doc['date_ssim'] = parsed_date.is_a?(EDTF::Interval) ? parsed_date.map(&:year).uniq : parsed_date.year
    end

    {
      'read_access_group_ssim' => read_groups,
      'read_access_person_ssim' => read_users,
      'discover_access_group_ssim' => discover_groups,
      'discover_access_person_ssim' => discover_users,
      'edit_access_group_ssim' => edit_groups,
      'edit_access_person_ssim' => edit_users
    }.each { |key, values| doc[key] = values if values.present? }

    doc
  end

  private

  def index_text_field(doc, field, sortable:, facetable:)
    values = Array(send(field)).map(&:to_s)
    return if values.empty?

    doc["#{field}_tesim"] = values
    doc["#{field}_ssi"] = values.first if sortable
    doc["#{field}_sim"] = values if facetable
  end

  def agent_names(agent_type, access_level)
    access_controls.where(agent_type: agent_type, access_level: access_level.to_s).pluck(:agent_name)
  end

  # Replaces all grants of this (agent_type, access_level) with exactly
  # `names`. Record must already be persisted - access_controls rows need
  # a real congressional_record_id to point at.
  def set_agents(agent_type, access_level, names)
    raise ActiveRecord::RecordNotSaved, "#{self.class} must be saved before setting permissions" if new_record?

    names = Array(names).map(&:to_s).reject(&:blank?).uniq
    access_controls.where(agent_type: agent_type, access_level: access_level.to_s)
                   .where.not(agent_name: names).destroy_all
    names.each do |name|
      access_controls.find_or_create_by!(agent_type: agent_type, access_level: access_level.to_s, agent_name: name)
    end
  end

  # Strips blank entries out of every array column automatically (no
  # hardcoded field list - works for creator/names/publisher/record_type/
  # date/language/congress/policy_area/topic/location_represented/project,
  # and keeps working if more array columns get added later). Mirrors
  # Acda#clear_empty_fields, adapted from ActiveTriples::Relation values to
  # plain Postgres arrays.
  def clear_empty_fields
    self.class.columns.each do |column|
      next unless column.respond_to?(:array?) && column.array?

      value = self[column.name]
      next unless value.is_a?(Array)

      self[column.name] = value.map { |v| v.is_a?(String) ? v.strip : v }.reject(&:blank?)
    end
  end

  # Mints an ID from `identifier` when one isn't already set - ported
  # verbatim from Acda#assign_id (strip protocol+domain, replace
  # URL-unsafe characters with underscores, drop periods). Only runs via
  # before_create when id is blank, so it never overwrites an explicitly
  # provided id (e.g. a migrated Fedora ID). Note: if `identifier` itself
  # is blank, this (faithfully, matching the original) produces an empty
  # string - not a usable primary key - so callers minting brand-new
  # records still need to ensure `identifier` is set first.
  def assign_id
    self.id = generate_id_from_identifier
  end

  def generate_id_from_identifier
    return '' if identifier.nil?

    cleaned = identifier.gsub(%r{https?://[^/]+/}, '')
    cleaned = cleaned.gsub(%r{[/:?%&=#+_]}, '_')
    cleaned = cleaned.delete('.')

    cleaned.delete('_').empty? ? '' : cleaned
  end
end
