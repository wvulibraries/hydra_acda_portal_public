# frozen_string_literal: true

module Bulkrax
  # Used to create Acda records when performing Bulkrax imports.
  # Based on Bulkrax's own Bulkrax::ObjectFactory.
  class AcdaFactory < ObjectFactory
    def initialize(**kwargs)
      @user = user || batch_user
      super(**kwargs, user: @user)
    end

    # Override if we need to map the attributes from the parser in
    # a way that is compatible with how the factory needs them.
    def transform_attributes(update: false)
      @transform_attributes = attributes.slice(*permitted_attributes)
      # TODO: implement with files or remove
      # @transform_attributes.merge!(file_attributes(update_files)) if with_files
      @transform_attributes = remove_blank_hash_values(@transform_attributes) if transformation_removes_blank_hash_values?
      # if we are updating an item, remove ID from the list of attributes.
      # ID should be ignored for existing works.
      # for all works, file path fields should be ignored.
      exceptions = update ? [:id] + file_path_field_names : file_path_field_names
      exceptions.each do |exception|
        transformed = @transform_attributes.except!(exception)
      end
      @transform_attributes
    end

    def run!
      @object = find

      object.present? ? update : create
      raise ActiveFedora::RecordInvalid, object unless object.persisted? || object.changed?

      object
    end

    def create
      @object = klass.new(transform_attributes)

      object.save!
      log_created(object)
    end

    def update
      raise "Object doesn't exist" unless object

      object.update(transform_attributes(update: true))
      log_updated(object)
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

    # Override if we need to map the attributes from the parser in
    # a way that is compatible with how the factory needs them.
    def transform_attributes(update: false)
      @transform_attributes = attributes.slice(*permitted_attributes)
      # TODO: implement with files or remove
      # @transform_attributes.merge!(file_attributes(update_files)) if with_files
      @transform_attributes = remove_blank_hash_values(@transform_attributes) if transformation_removes_blank_hash_values?
      # if we are updating an item, remove ID from the list of attributes.
      # ID should be ignored for existing works.
      # for all works, file path fields should be ignored.
      exceptions = update ? [:id] + file_path_field_names : file_path_field_names
      exceptions.each do |exception|
        transformed = @transform_attributes.except!(exception)
      end
      @transform_attributes
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

    # This method mimics the User.batch_user method in a Hyrax app.
    # @see https://github.com/samvera/hyrax/blob/76176286b817c869a80b922ccacc6fecea3827e2/app/models/concerns/hyrax/user.rb#L154-L185
    def batch_user
      user_key = 'batchuser@example.com'

      User.find_by_user_key(user_key) ||
        User.create!(Hydra.config.user_key_field => user_key, password: Devise.friendly_token[0, 20])
    end
  end
end
