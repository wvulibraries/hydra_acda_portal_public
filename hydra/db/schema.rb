# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_06_08_153601) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bookmarks", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "user_type"
    t.string "document_id"
    t.string "document_type"
    t.binary "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_error_at"
    t.datetime "last_succeeded_at"
    t.string "importerexporter_type", default: "Bulkrax::Importer"
    t.integer "import_attempts", default: 0
    t.index ["identifier"], name: "index_bulkrax_entries_on_identifier"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_error_at"
    t.datetime "last_succeeded_at"
    t.date "start_date"
    t.date "finish_date"
    t.string "work_visibility"
    t.string "workflow_status"
    t.boolean "include_thumbnails", default: false
    t.boolean "generated_metadata", default: false
    t.index ["user_id"], name: "index_bulkrax_exporters_on_user_id"
  end

  create_table "bulkrax_importer_runs", force: :cascade do |t|
    t.bigint "importer_id"
    t.integer "total_work_entries", default: 0
    t.integer "enqueued_records", default: 0
    t.integer "processed_records", default: 0
    t.integer "deleted_records", default: 0
    t.integer "failed_records", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "validate_only"
    t.datetime "last_error_at"
    t.datetime "last_succeeded_at"
    t.index ["user_id"], name: "index_bulkrax_importers_on_user_id"
  end

  create_table "bulkrax_pending_relationships", force: :cascade do |t|
    t.bigint "importer_run_id", null: false
    t.string "parent_id", null: false
    t.string "child_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order", default: 0
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["error_class"], name: "index_bulkrax_statuses_on_error_class"
    t.index ["runnable_id", "runnable_type"], name: "bulkrax_statuses_runnable_idx"
    t.index ["statusable_id", "statusable_type"], name: "bulkrax_statuses_statusable_idx"
  end

  create_table "searches", id: :serial, force: :cascade do |t|
    t.binary "query_params"
    t.integer "user_id"
    t.string "user_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "guest", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "bulkrax_exporter_runs", "bulkrax_exporters", column: "exporter_id"
  add_foreign_key "bulkrax_importer_runs", "bulkrax_importers", column: "importer_id"
  add_foreign_key "bulkrax_pending_relationships", "bulkrax_importer_runs", column: "importer_run_id"
end
