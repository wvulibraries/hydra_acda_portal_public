# This migration creates the ActiveStorage tables (active_storage_blobs,
# active_storage_attachments, active_storage_variant_records).
#
# NOTE: this app already has three *follow-up* ActiveStorage migrations
# (20231010212024_add_service_name_to_active_storage_blobs,
#  20231010212025_create_active_storage_variant_records,
#  20231016223832_remove_not_null_on_active_storage_blobs_checksum)
# but the original *base* migration that actually creates
# active_storage_blobs/active_storage_attachments was never added to this
# repo, so none of those tables exist yet and `has_one_attached` has never
# been usable here. Those three migrations all guard with
# `return unless table_exists?(:active_storage_blobs)`, so they already ran
# as no-ops and are marked complete in schema_migrations - they will NOT
# re-run just because this table now exists. This migration creates the
# tables directly in their final shape (service_name included, no NOT NULL
# on checksum, variant_records included).
#
# FIX: the first version of this file used a `primary_key_type` helper
# (copied from Rails' own template) that can resolve to the literal symbol
# :primary_key. That's only valid as `create_table id: ...` - passed as a
# column `type:` on Postgres it emits a full "bigserial primary key"
# definition, colliding with the table's real id column. This app doesn't
# use UUIDs or any custom primary key type anywhere else, so we just use
# Rails' plain bigint defaults everywhere instead of that dynamic helper.
class CreateActiveStorageTables < ActiveRecord::Migration[7.0]
  def change
    create_table :active_storage_blobs do |t|
      t.string   :key,          null: false
      t.string   :filename,     null: false
      t.string   :content_type
      t.text     :metadata
      t.string   :service_name, null: false
      t.bigint   :byte_size,    null: false
      t.string   :checksum

      t.datetime :created_at, null: false

      t.index [:key], unique: true
    end

    create_table :active_storage_attachments do |t|
      t.string     :name,     null: false
      t.references :record,   null: false, polymorphic: true, index: false
      t.references :blob,     null: false

      t.datetime :created_at, null: false

      t.index [:record_type, :record_id, :name, :blob_id], name: "index_active_storage_attachments_uniqueness", unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end

    create_table :active_storage_variant_records do |t|
      t.belongs_to :blob, null: false, index: false
      t.string :variation_digest, null: false

      t.index %i[blob_id variation_digest], name: "index_active_storage_variant_records_uniqueness", unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  end
end
