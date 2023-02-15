# frozen_string_literal: true

module Bulkrax
  # Used to create Acda records when performing Bulkrax imports.
  # Based on Bulkrax's own Bulkrax::ObjectFactory.
  class AcdaFactory
    attr_reader :attributes, :object, :source_identifier_value,
                :klass, :replace_files, :update_files, :work_identifier,
                :related_parents_parsed_mapping, :importer_run_id

    def initialize(attributes:, source_identifier_value:, work_identifier:, related_parents_parsed_mapping: nil, replace_files: false, user: nil, klass: nil, importer_run_id: nil, update_files: false)
      @attributes = ActiveSupport::HashWithIndifferentAccess.new(attributes)
      @user = user || User.batch_user
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

    # TODO: implement
    def create; end

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
  end
end
