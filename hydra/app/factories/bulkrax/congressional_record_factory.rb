module Bulkrax
  # ActiveRecord/ActiveStorage equivalent of Bulkrax's own ObjectFactory, for
  # creating/updating CongressionalRecord. Live factory for all Bulkrax
  # imports/edits (see config/initializers/bulkrax.rb).
  #
  # Inherits directly from Bulkrax::ObjectFactory (not AcdaFactory -
  # Acda/ActiveFedora are being removed). find/find_by_id/
  # search_by_identifier/transform_attributes/file_path_field_names/
  # batch_user below are ported verbatim from the old AcdaFactory so
  # behavior doesn't change.
  #
  # Two real incompatibilities with naively using Bulkrax's defaults, both
  # handled here:
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
  class CongressionalRecordFactory < ObjectFactory
    PERMISSION_ATTRIBUTE_NAMES = %i[
      visibility read_groups read_users edit_groups edit_users discover_groups discover_users
    ].freeze

    INTERNAL_COLUMNS = %i[created_at updated_at queued_job].freeze

    def initialize(**kwargs)
      @user = user || batch_user
      super(**kwargs, user: @user)
    end

    def permitted_attributes
      klass.column_names.map(&:to_sym) - INTERNAL_COLUMNS + base_permitted_attributes
    end

    # Override if we need to map the attributes from the parser in
    # a way that is compatible with how the factory needs them.
    def transform_attributes(update: false)
      @transform_attributes = attributes.slice(*permitted_attributes)
      @transform_attributes = remove_blank_hash_values(@transform_attributes) if transformation_removes_blank_hash_values?
      # if we are updating an item, remove ID from the list of attributes.
      # ID should be ignored for existing works.
      # for all works, file path fields should be ignored.
      exceptions = update ? [:id] + file_path_field_names : file_path_field_names
      exceptions.each do |exception|
        @transform_attributes.except!(exception)
      end
      @transform_attributes
    end

    def create
      attrs = transform_attributes
      permission_attrs = attrs.slice(*PERMISSION_ATTRIBUTE_NAMES)

      @object = klass.new(attrs.except(*PERMISSION_ATTRIBUTE_NAMES))
      object.save!

      permission_attrs.each { |key, value| object.public_send("#{key}=", value) }

      log_created(object)
    end

    def update
      raise "Object doesn't exist" unless object

      object.update(transform_attributes(update: true))
      log_updated(object)
    end

    def run!
      @object = find

      object.present? ? update : create
      raise ActiveRecord::RecordInvalid, object unless object.persisted? || object.changed?

      object
    end

    def find
      return find_by_id if attributes[:id].present?
      return search_by_identifier if attributes[work_identifier].present?
    end

    def find_by_id
      klass.find(attributes[:id]) if klass.exists?(attributes[:id])
    end

    def search_by_identifier
      query = { work_identifier => source_identifier_value }
      # Query can return partial matches (something6 matches both something6 and something68)
      # so we need to weed out any that are not the correct full match. But other items might be
      # in the multivalued field, so we have to go through them one at a time.
      match = klass.where(query).detect { |m| m.send(work_identifier).include?(source_identifier_value) }
      return match if match
    end

    # When creating a CongressionalRecord, these all get filtered out of the metadata.
    #
    # @return [Array<Symbol>] List of all ingestable <file>_path field names
    def file_path_field_names
      %i[
        audio_path
        image_path
        pdf_path
        thumb_path
        video_path
        pdf_image_path
        pdf_thumb_path
        video_image_path
        video_thumb_path
      ]
    end

    # This method mimics the User.batch_user method in a Hyrax app.
    # @see https://github.com/samvera/hyrax/blob/76176286b817c869a80b922ccacc6fecea3827e2/app/models/concerns/hyrax/user.rb#L154-L185
    #
    # Race condition fix: With higher GoodJob concurrency (multiple import
    # threads running at once), separate threads can each check for the batch
    # user, find none, and all try to create it simultaneously - only one
    # succeeds, the rest raise ActiveRecord::RecordInvalid. Rescue and re-fetch
    # to handle that safely.
    # solves bulrax errors - ActiveRecord::RecordInvalid - Validation failed: Email has already been taken
    def batch_user
      user_key = 'batchuser@example.com'
      User.find_by_user_key(user_key) ||
        User.create!(email: user_key, password: Devise.friendly_token[0, 20])
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      User.find_by_user_key(user_key)
    end
  end
end