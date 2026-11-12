module Bulkrax
  # ActiveRecord/ActiveStorage equivalent of Bulkrax::AcdaFactory, for
  # creating/updating CongressionalRecord instead of Acda.
  #
  # NOT wired up yet - config.object_factory/default_work_type/
  # curation_concerns in config/initializers/bulkrax.rb still point at
  # Acda/AcdaFactory. This exists so it can be tested against real import
  # data before that cutover happens.
  #
  # Two real incompatibilities with naively swapping Acda -> CongressionalRecord
  # inside AcdaFactory, both handled here:
  #   1. permitted_attributes (inherited from Bulkrax's base factory code)
  #      calls klass.properties.keys, which is ActiveFedora-only.
  #      CongressionalRecord has no #properties - overridden below using
  #      column_names instead.
  #   2. Bulkrax's default create path mass-assigns permission attributes
  #      (read_groups/edit_groups/edit_users/visibility) via klass.new(...)
  #      BEFORE the record is saved. Our permission setters write to the
  #      access_controls table via a foreign key to the record's id, which
  #      doesn't exist until the record is first saved - they raise
  #      RecordNotSaved on an unsaved record. #create below splits
  #      permission attributes out and applies them after the initial save.
  class CongressionalRecordFactory < AcdaFactory
    PERMISSION_ATTRIBUTE_NAMES = %i[
      visibility read_groups read_users edit_groups edit_users discover_groups discover_users
    ].freeze

    INTERNAL_COLUMNS = %i[created_at updated_at queued_job].freeze

    def permitted_attributes
      klass.column_names.map(&:to_sym) - INTERNAL_COLUMNS + base_permitted_attributes
    end

    def create
      attrs = transform_attributes
      permission_attrs = attrs.slice(*PERMISSION_ATTRIBUTE_NAMES)

      @object = klass.new(attrs.except(*PERMISSION_ATTRIBUTE_NAMES))
      object.save!

      permission_attrs.each { |key, value| object.public_send("#{key}=", value) }

      log_created(object)
    end

    def run!
      @object = find

      object.present? ? update : create
      raise ActiveRecord::RecordInvalid, object unless object.persisted? || object.changed?

      object
    end
  end
end