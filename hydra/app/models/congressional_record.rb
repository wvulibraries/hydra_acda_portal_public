# ActiveRecord replacement for the ActiveFedora-backed Acda model.
# File attachments, the access_controls association, the permission
# getters/setters + computed visibility, and blank-value cleanup on save.
#
# Deliberately NOT included yet (separate, later steps):
#   - assign_id (Fedora-style ID minting from `identifier`)
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

  private

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
end
