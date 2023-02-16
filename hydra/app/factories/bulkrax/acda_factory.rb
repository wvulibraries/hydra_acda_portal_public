# frozen_string_literal: true

module Bulkrax
  # Used to create Acda records when performing Bulkrax imports.
  # Based on Bulkrax's own Bulkrax::ObjectFactory.
  class AcdaFactory
    # @api private
    #
    # These are the attributes that we assume all "work type" classes (e.g. the given :klass) will
    # have in addition to their specific attributes.
    #
    # @return [Array<Symbol>]
    # @see #permitted_attributes
    class_attribute :base_permitted_attributes,
                    default: %i[id edit_users edit_groups read_groups visibility]

    # @return [Boolean]
    #
    # @example
    #   Bulkrax::ObjectFactory.transformation_removes_blank_hash_values = true
    #
    # @see #transform_attributes
    # @see https://github.com/samvera-labs/bulkrax/pull/708 For discussion concerning this feature
    # @see https://github.com/samvera-labs/bulkrax/wiki/Interacting-with-Metadata For documentation
    #      concerning default behavior.
    class_attribute :transformation_removes_blank_hash_values, default: false

    attr_reader :attributes, :object, :source_identifier_value,
                :klass, :replace_files, :update_files, :work_identifier,
                :related_parents_parsed_mapping, :importer_run_id

    def initialize(attributes:, source_identifier_value:, work_identifier:, related_parents_parsed_mapping: nil, replace_files: false, user: nil, klass: nil, importer_run_id: nil, update_files: false)
      @attributes = ActiveSupport::HashWithIndifferentAccess.new(attributes)
      @user = user || batch_user
      @importer_run_id = importer_run_id
      @work_identifier = work_identifier
      @source_identifier_value = source_identifier_value
      @related_parents_parsed_mapping = related_parents_parsed_mapping
      @replace_files = replace_files
      @update_files = update_files
      @klass = klass || Bulkrax.default_work_type.constantize
    end

    def run!
      @object = find

      object.present? ? update : create
      raise ActiveFedora::RecordInvalid, object if !object.persisted? || object.changed?

      object
    end

    def create
      @object = klass.new(transform_attributes)

      object.save!
      log_created(object)
    end

    # TODO: implement
    def update; end

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

    # Override if we need to map the attributes from the parser in
    # a way that is compatible with how the factory needs them.
    def transform_attributes(update: false)
      @transform_attributes = attributes.slice(*permitted_attributes)
      # TODO: implement with files or remove
      # @transform_attributes.merge!(file_attributes(update_files)) if with_files
      @transform_attributes = remove_blank_hash_values(@transform_attributes) if transformation_removes_blank_hash_values?
      # TODO: Should we filter these out earlier in the process? I.e. before they get into :attributes or when we're
      #       parsing the metadata? I don't think we currently know enough about what :attributes will look like
      #       at this point to say for sure yet.
      exceptions = update ? [:id] + file_path_field_names : file_path_field_names

      @transform_attributes.except(exceptions)
    end

    # Regardless of what the Parser gives us, these are the properties we are prepared to accept.
    def permitted_attributes
      klass.properties.keys.map(&:to_sym) + base_permitted_attributes
    end

    # When creating an Acda record, these all get filtered out of the metadata.
    # @see ImportLibrary#create_new_record
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

    # Return a copy of the given attributes, such that all values that are empty or an array of all
    # empty values are fully emptied.  (See implementation details)
    #
    # @param attributes [Hash]
    # @return [Hash]
    #
    # @see https://github.com/emory-libraries/dlp-curate/issues/1973
    def remove_blank_hash_values(attributes)
      dupe = attributes.dup
      dupe.each do |key, values|
        if values.is_a?(Array) && values.all? { |value| value.is_a?(String) && value.empty? }
          dupe[key] = []
        elsif values.is_a?(String) && values.empty?
          dupe[key] = nil
        end
      end
      dupe
    end

    def log_created(obj)
      msg = "Created #{obj.class} #{obj.id}"
      Rails.logger.info("#{msg} (#{Array(attributes[work_identifier]).first})")
    end

    # This method mimics the User.batch_user method in a Hyrax app.
    # @see https://github.com/samvera/hyrax/blob/76176286b817c869a80b922ccacc6fecea3827e2/app/models/concerns/hyrax/user.rb#L154-L185
    def batch_user
      user_key = 'batchuser@example.com'

      User.find_by_user_key(user_key) ||
        User.create!(Hydra.config.user_key_field => user_key, password: Devise.friendly_token[0, 20])
    end
  end
end
