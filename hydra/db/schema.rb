# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2026_11_10_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_controls", force: :cascade do |t|
    t.string "congressional_record_id", null: false
    t.string "agent_type", null: false
    t.string "agent_name", null: false
    t.string "access_level", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["congressional_record_id", "agent_type", "agent_name", "access_level"], name: "index_access_controls_uniqueness", unique: true
    t.index ["congressional_record_id"], name: "index_access_controls_on_congressional_record_id"
    t.check_constraint "access_level::text = ANY (ARRAY['discover'::character varying, 'read'::character varying, 'edit'::character varying]::text[])", name: "access_controls_access_level_check"
    t.check_constraint "agent_type::text = ANY (ARRAY['person'::character varying, 'group'::character varying]::text[])", name: "access_controls_agent_type_check"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.string "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bookmarks", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "user_type"
    t.string "document_id"
    t.string "document_type"
    t.binary "title"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["document_id"], name: "index_bookmarks_on_document_id"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "bulkrax_entries", force: :cascade do |t|
    t.string "identifier"
    t.string "collection_ids"
    t.string "type"
    t.bigint "importerexporter_id"
    t.text "raw_metadata"
    t.text "parsed_metadata"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "last_error_at", precision: nil
    t.datetime "last_succeeded_at", precision: nil
    t.string "importerexporter_type", default: "Bulkrax::Importer"
    t.integer "import_attempts", default: 0
    t.string "status_message", default: "Pending"
    t.string "error_class"
    t.index ["identifier", "importerexporter_id", "importerexporter_type"], name: "bulkrax_identifier_idx"
    t.index ["importerexporter_id", "importerexporter_type", "id"], name: "index_bulkrax_entries_on_importerexporter_id_type_and_id"
    t.index ["importerexporter_id", "importerexporter_type"], name: "bulkrax_entries_importerexporter_idx"
    t.index ["type"], name: "index_bulkrax_entries_on_type"
  end

  create_table "bulkrax_exporter_runs", force: :cascade do |t|
    t.bigint "exporter_id"
    t.integer "total_work_entries", default: 0
    t.integer "enqueued_records", default: 0
    t.integer "processed_records", default: 0
    t.integer "deleted_records", default: 0
    t.integer "failed_records", default: 0
    t.index ["exporter_id"], name: "index_bulkrax_exporter_runs_on_exporter_id"
  end

  create_table "bulkrax_exporters", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id"
    t.string "parser_klass"
    t.integer "limit"
    t.text "parser_fields"
    t.text "field_mapping"
    t.string "export_source"
    t.string "export_from"
    t.string "export_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "last_error_at", precision: nil
    t.datetime "last_succeeded_at", precision: nil
    t.date "start_date"
    t.date "finish_date"
    t.string "work_visibility"
    t.string "workflow_status"
    t.boolean "include_thumbnails", default: false
    t.boolean "generated_metadata", default: false
    t.string "status_message", default: "Pending"
    t.string "error_class"
    t.index ["user_id"], name: "index_bulkrax_exporters_on_user_id"
  end

  create_table "bulkrax_importer_runs", force: :cascade do |t|
    t.bigint "importer_id"
    t.integer "total_work_entries", default: 0
    t.integer "enqueued_records", default: 0
    t.integer "processed_records", default: 0
    t.integer "deleted_records", default: 0
    t.integer "failed_records", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "processed_collections", default: 0
    t.integer "failed_collections", default: 0
    t.integer "total_collection_entries", default: 0
    t.integer "processed_relationships", default: 0
    t.integer "failed_relationships", default: 0
    t.text "invalid_records"
    t.integer "processed_file_sets", default: 0
    t.integer "failed_file_sets", default: 0
    t.integer "total_file_set_entries", default: 0
    t.integer "processed_works", default: 0
    t.integer "failed_works", default: 0
    t.index ["importer_id"], name: "index_bulkrax_importer_runs_on_importer_id"
  end

  create_table "bulkrax_importers", force: :cascade do |t|
    t.string "name"
    t.string "admin_set_id"
    t.bigint "user_id"
    t.string "frequency"
    t.string "parser_klass"
    t.integer "limit"
    t.text "parser_fields"
    t.text "field_mapping"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "validate_only"
    t.datetime "last_error_at", precision: nil
    t.datetime "last_succeeded_at", precision: nil
    t.string "status_message", default: "Pending"
    t.datetime "last_imported_at", precision: nil
    t.datetime "next_import_at", precision: nil
    t.string "error_class"
    t.index ["user_id"], name: "index_bulkrax_importers_on_user_id"
  end

  create_table "bulkrax_pending_relationships", force: :cascade do |t|
    t.bigint "importer_run_id", null: false
    t.string "parent_id", null: false
    t.string "child_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "order", default: 0
    t.string "status_message", default: "Pending"
    t.index ["child_id"], name: "index_bulkrax_pending_relationships_on_child_id"
    t.index ["importer_run_id"], name: "index_bulkrax_pending_relationships_on_importer_run_id"
    t.index ["parent_id"], name: "index_bulkrax_pending_relationships_on_parent_id"
  end

  create_table "bulkrax_statuses", force: :cascade do |t|
    t.string "status_message"
    t.string "error_class"
    t.text "error_message"
    t.text "error_backtrace"
    t.integer "statusable_id"
    t.string "statusable_type"
    t.integer "runnable_id"
    t.string "runnable_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["error_class"], name: "index_bulkrax_statuses_on_error_class"
    t.index ["runnable_id", "runnable_type"], name: "bulkrax_statuses_runnable_idx"
    t.index ["statusable_id", "statusable_type"], name: "bulkrax_statuses_statusable_idx"
  end

  create_table "congressional_records", id: :string, force: :cascade do |t|
    t.string "bulkrax_identifier"
    t.string "identifier"
    t.string "title"
    t.text "description"
    t.string "creator", default: [], array: true
    t.string "names", default: [], array: true
    t.string "publisher", default: [], array: true
    t.string "contributing_institution"
    t.string "rights"
    t.string "extent"
    t.string "dc_type"
    t.string "record_type", default: [], array: true
    t.string "date", default: [], array: true
    t.string "edtf"
    t.string "language", default: [], array: true
    t.string "congress", default: [], array: true
    t.string "policy_area", default: [], array: true
    t.string "topic", default: [], array: true
    t.string "location_represented", default: [], array: true
    t.string "collection_title"
    t.string "physical_location"
    t.string "collection_finding_aid"
    t.string "preview"
    t.string "available_at"
    t.string "available_by"
    t.string "project", default: [], array: true
    t.string "queued_job"
    t.string "state", default: "draft"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bulkrax_identifier"], name: "index_congressional_records_on_bulkrax_identifier", unique: true
    t.index ["identifier"], name: "index_congressional_records_on_identifier"
    t.index ["project"], name: "index_congressional_records_on_project", using: :gin
    t.index ["state"], name: "index_congressional_records_on_state"
    t.index ["title"], name: "index_congressional_records_on_title"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
    t.datetime "jobs_finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.text "error_backtrace", array: true
    t.uuid "process_id"
    t.interval "duration"
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
    t.integer "lock_type", limit: 2
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.uuid "locked_by_id"
    t.datetime "locked_at"
    t.integer "lock_type", limit: 2
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key", "created_at"], name: "index_good_jobs_on_concurrency_key_and_created_at"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["created_at"], name: "index_good_jobs_on_created_at"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at_only", where: "(finished_at IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_on_discarded", order: :desc, where: "((finished_at IS NOT NULL) AND (error IS NOT NULL))"
    t.index ["id"], name: "index_good_jobs_on_unfinished_or_errored", where: "((finished_at IS NULL) OR (error IS NOT NULL))"
    t.index ["job_class"], name: "index_good_jobs_on_job_class"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at", "id"], name: "index_good_jobs_for_candidate_dequeue_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["priority", "scheduled_at", "id"], name: "index_good_jobs_on_priority_scheduled_at_unfinished", where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at", "id"], name: "index_good_jobs_on_queue_name_priority_scheduled_at_unfinished", where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["queue_name"], name: "index_good_jobs_on_queue_name"
    t.index ["scheduled_at", "queue_name"], name: "index_good_jobs_on_scheduled_at_and_queue_name"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "searches", id: :serial, force: :cascade do |t|
    t.binary "query_params"
    t.integer "user_id"
    t.string "user_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "url_checks", force: :cascade do |t|
    t.string "url", null: false
    t.boolean "active", default: false, null: false
    t.datetime "last_checked_at"
    t.string "status", default: "pending"
    t.integer "retry_count", default: 0
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_url_checks_on_status"
    t.index ["url"], name: "index_url_checks_on_url", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "guest", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "access_controls", "congressional_records"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bulkrax_exporter_runs", "bulkrax_exporters", column: "exporter_id"
  add_foreign_key "bulkrax_importer_runs", "bulkrax_importers", column: "importer_id"
  add_foreign_key "bulkrax_pending_relationships", "bulkrax_importer_runs", column: "importer_run_id"
end
