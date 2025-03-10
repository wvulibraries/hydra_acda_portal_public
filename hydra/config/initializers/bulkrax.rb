# frozen_string_literal: true

# TODO: investigate why to_prepare is needed
Rails.application.config.to_prepare do
  Bulkrax.setup do |config|
    # Add local parsers
    config.parsers = [
      { name: 'CSV - Comma Separated Values', class_name: 'Bulkrax::CsvParser', partial: 'wv_csv_fields' }
    ]

    # WorkType to use as the default if none is specified in the import
    # Default is the first returned by Hyrax.config.curation_concerns
    config.default_work_type = 'Acda'

    # Factory Class to use when generating and saving objects
    config.object_factory = Bulkrax::AcdaFactory

    # File model for file class
    config.file_model_class = AcdaFile

    # curation_concerns, Default =  Hyrax.config.curation_concerns
    config.curation_concerns = [Acda]

    config.qa_controlled_properties = []

    # Path to store pending imports
    # config.import_path = 'tmp/imports'

    # Path to store exports before download
    # config.export_path = 'tmp/exports'

    # Server name for oai request header
    # config.server_name = 'my_server@name.com'

    # NOTE: Creating Collections using the collection_field_mapping will no longer be supported as of Bulkrax version 3.0.
    #       Please configure Bulkrax to use related_parents_field_mapping and related_children_field_mapping instead.
    # Field_mapping for establishing a collection relationship (FROM work TO collection)
    # This value IS NOT used for OAI, so setting the OAI parser here will have no effect
    # The mapping is supplied per Entry, provide the full class name as a string, eg. 'Bulkrax::CsvEntry'
    # The default value for CSV is collection
    # Add/replace parsers, for example:
    # config.collection_field_mapping['Bulkrax::RdfEntry'] = 'http://opaquenamespace.org/ns/set'

    # Field mappings
    # Create a completely new set of mappings by replacing the whole set as follows
    config.field_mappings = {
      'Bulkrax::CsvParser' => {
        'contributing_institution' => { from: ['dcterms:provenance'] },
        'title' => { from: ['dcterms:title'] },
        'date' => { from: ['dcterms:date'], split: true },
        'edtf' => { from: ['dcterms:created'] },
        'creator' => { from: ['dcterms:creator'], split: true },
        'rights' => { from: ['dcterms:rights'] },
        'language' => { from: ['dcterms:language'], split: true },
        'congress' => { from: ['dcterms:temporal'], split: true },
        'collection_title' => { from: ['dcterms:relation'] },
        'physical_location' => { from: ['dcterms:isPartOf'] },
        'collection_finding_aid' => { from: ['dcterms:source'] },
        'bulkrax_identifier' => { from: ['bulkrax_identifier'], source_identifier: true },
        'identifier' => { from: ['dcterms:identifier'] },
        'topic' => { from: ['dcterms:http://purl.org/dc/elements/1.1/subject'], split: true },
        'preview' => { from: ['edm:preview'] },
        'available_at' => { from: ['edm:isShownAt'] },
        'available_by' => { from: ['edm:isShownBy'] },
        'description' => { from: ['dcterms:description'] },
        'names' => { from: ['dcterms:contributor'], split: true },
        'dc_type' => { from: ['dcterms:type'] },
        'record_type' => { from: ['dcterms:http://purl.org/dc/terms/type'], split: true },
        'location_represented' => { from: ['dcterms:spatial'], split: true },
        'extent' => { from: ['dcterms:format'] },
        'publisher' => { from: ['dcterms:publisher'], split: true },
        'policy_area' => { from: ['dcterms:subject'], split: true }
      }
    }

    # Add to, or change existing mappings as follows
    #   e.g. to exclude date
    #   config.field_mappings["Bulkrax::OaiDcParser"]["date"] = { from: ["date"], excluded: true  }
    #
    #   e.g. to import parent-child relationships
    #   config.field_mappings['Bulkrax::CsvParser']['parents'] = { from: ['parents'], related_parents_field_mapping: true }
    #   config.field_mappings['Bulkrax::CsvParser']['children'] = { from: ['children'], related_children_field_mapping: true }
    #   (For more info on importing relationships, see Bulkrax Wiki: https://github.com/samvera-labs/bulkrax/wiki/Configuring-Bulkrax#parent-child-relationship-field-mappings)
    #
    # #   e.g. to add the required source_identifier field
    #   #   config.field_mappings["Bulkrax::CsvParser"]["source_id"] = { from: ["old_source_id"], source_identifier: true  }
    # If you want Bulkrax to fill in source_identifiers for you, see below

    # To duplicate a set of mappings from one parser to another
    #   config.field_mappings["Bulkrax::OaiOmekaParser"] = {}
    #   config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiOmekaParser"][key] = value }

    # Should Bulkrax make up source identifiers for you? This allow round tripping
    # and download errored entries to still work, but does mean if you upload the
    # same source record in two different files you WILL get duplicates.
    # It is given two aruguments, self at the time of call and the index of the record
    config.fill_in_blank_source_identifiers = ->(parser, index) { "b-#{parser.importer.id}-#{index}"}
    # or use a uuid
    #    config.fill_in_blank_source_identifiers = ->(parser, index) { SecureRandom.uuid }

    # Properties that should not be used in imports/exports. They are reserved for use by Hyrax.
    # config.reserved_properties += ['my_field']

    # List of Questioning Authority properties that are controlled via YAML files in
    # the config/authorities/ directory. For example, the :rights_statement property
    # is controlled by the active terms in config/authorities/rights_statements.yml
    # Defaults: 'rights_statement' and 'license'
    # config.qa_controlled_properties += ['my_field']

    # Specify the delimiter regular expression for splitting an attribute's values into a multi-value array.
    config.multi_value_element_split_on = /\s*[;]\s*/.freeze

    # Specify the delimiter for joining an attribute's multi-value array into a string.  Note: the
    # specific delimeter should likely be present in the multi_value_element_split_on expression.
    # config.multi_value_element_join_on = ' | '
  end
end
