# Phase 1.2: PostgreSQL-backed replacement for the ActiveFedora-backed Acda
# model. Field list is cross-checked against the live app/models/acda.rb
# (27 explicit RDF properties), the Solr indexer (app/indexers/indexer.rb),
# and the Bulkrax CSV field mapping (config/initializers/bulkrax.rb) - all
# three agree, nothing added or dropped relative to what's used today.
#
# Access control (edit/read/discover x users/groups) is NOT stored here as
# array columns - it lives in a separate `access_controls` table (see the
# next migration), mirroring how Hydra::AccessControls::Permissions works
# today (one row per grant) rather than flattening it into arrays.
#
# `visibility` has no column at all: today it's computed from read_groups
# containing the 'public'/'registered' group names (see
# Hydra::AccessControls::Visibility), and the new model will replicate that
# same computed method against the access_controls table instead of storing
# it directly.
#
# `queued_job` is a string, not an integer: the live model stores literal
# string states ('true'/'completed') in it, never a number.
#
# `id` is a string primary key (not a generated UUID/bigint) so the
# existing Fedora-style ID values can be reused as-is - they're already
# referenced externally (Bulkrax identifiers, Solr docs, permalinks).
class CreateCongressionalRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :congressional_records, id: :string do |t|
      # External identifiers
      t.string :bulkrax_identifier
      t.string :identifier

      # Core descriptive metadata
      t.string :title
      t.text   :description
      t.string :creator,   array: true, default: []
      t.string :names,     array: true, default: [] # DC contributor
      t.string :publisher, array: true, default: []
      t.string :contributing_institution
      t.string :rights
      t.string :extent
      t.string :dc_type # drives which viewer renders the record (Image/Sound/Text/etc.)
      t.string :record_type, array: true, default: []

      # Dates
      t.string :date, array: true, default: []
      t.string :edtf # not shown in the UI, mirrors Acda#edtf

      # Subjects / classification
      t.string :language,             array: true, default: []
      t.string :congress,             array: true, default: [] # DC temporal
      t.string :policy_area,          array: true, default: [] # DC subject
      t.string :topic,                array: true, default: [] # internal subject predicate
      t.string :location_represented, array: true, default: [] # DC spatial

      # Collection context
      t.string :collection_title
      t.string :physical_location
      t.string :collection_finding_aid

      # External links / thumbnail
      t.string :preview
      t.string :available_at
      t.string :available_by

      # Project + import workflow
      t.string :project, array: true, default: []
      t.string :queued_job # string state ('true' / 'completed'), not a counter

      # New workflow field (no Fedora equivalent)
      t.string :state, default: 'draft'

      t.timestamps
    end

    add_index :congressional_records, :title
    add_index :congressional_records, :state
    add_index :congressional_records, :project, using: :gin
    add_index :congressional_records, :identifier
    # Bulkrax's find/update path keys off this; a DB-enforced unique index
    # here closes the Ldp::Conflict race from acda_factory.rb by enforcing
    # uniqueness at the DB level instead of a Solr existence check.
    add_index :congressional_records, :bulkrax_identifier, unique: true
  end
end
