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

ActiveRecord::Schema[8.0].define(version: 2024_12_12_157250) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
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

  create_table "districts", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "issue_categories", force: :cascade do |t|
    t.string "category"
    t.string "category_hu"
    t.string "category_alias"
    t.string "description"
    t.string "description_hu"
    t.boolean "catch_all", default: false
    t.bigint "parent_id", null: false
    t.integer "weight"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_issue_categories_on_parent_id"
  end

  create_table "issues", force: :cascade do |t|
    t.string "title", null: false
    t.string "description", null: false
    t.string "author", null: false
    t.datetime "reported_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_synced_at"
    t.integer "triage_external_id"
    t.string "state"
    t.jsonb "legacy_data"
  end

  create_table "issues_drafts", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.string "author"
    t.boolean "anonymous"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.jsonb "suggestions", default: []
    t.integer "picked_suggestion_index"
    t.jsonb "checks"
    t.string "address_house_number"
    t.string "address_road"
    t.string "address_neighbourhood"
    t.string "address_town"
    t.string "address_suburb"
    t.string "address_city_district"
    t.string "address_city"
    t.string "address_state"
    t.string "address_postcode"
    t.string "address_country"
    t.string "address_country_code"
    t.string "address_village"
    t.string "category"
    t.string "subcategory"
    t.string "subtype"
  end

  create_table "municipalities", force: :cascade do |t|
    t.string "name"
    t.bigint "district_id", null: false
    t.string "sub"
    t.string "alias"
    t.string "email"
    t.integer "municipality_type"
    t.boolean "has_municipality_districts"
    t.integer "handled_by"
    t.float "latitude"
    t.float "longitude"
    t.integer "population"
    t.boolean "active"
    t.integer "category"
    t.string "languages"
    t.string "logo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_municipalities_on_active"
    t.index ["alias"], name: "index_municipalities_on_alias"
    t.index ["district_id"], name: "index_municipalities_on_district_id"
    t.index ["latitude"], name: "index_municipalities_on_latitude"
    t.index ["longitude"], name: "index_municipalities_on_longitude"
  end

  create_table "municipality_districts", force: :cascade do |t|
    t.string "name"
    t.bigint "municipality_id", null: false
    t.string "genitiv"
    t.string "lokal"
    t.string "description"
    t.string "logo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["municipality_id"], name: "index_municipality_districts_on_municipality_id"
  end

  create_table "responsible_subject_categories", force: :cascade do |t|
    t.bigint "responsible_subject_id", null: false
    t.bigint "issue_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_category_id"], name: "index_responsible_subject_categories_on_issue_category_id"
    t.index ["responsible_subject_id"], name: "index_responsible_subject_categories_on_responsible_subject_id"
  end

  create_table "responsible_subject_types", force: :cascade do |t|
    t.string "name"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "responsible_subjects", force: :cascade do |t|
    t.bigint "district_id", null: false
    t.bigint "municipality_id", null: false
    t.bigint "responsible_subject_type_id", null: false
    t.integer "scope"
    t.string "email"
    t.string "name"
    t.string "code"
    t.boolean "active"
    t.boolean "pro"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["district_id"], name: "index_responsible_subjects_on_district_id"
    t.index ["municipality_id"], name: "index_responsible_subjects_on_municipality_id"
    t.index ["responsible_subject_type_id"], name: "index_responsible_subjects_on_responsible_subject_type_id"
  end

  create_table "streets", force: :cascade do |t|
    t.string "name"
    t.bigint "municipality_id", null: false
    t.bigint "municipality_district_id", null: false
    t.string "place_identifier"
    t.float "latitude"
    t.float "longitude"
    t.boolean "tested"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["latitude"], name: "index_streets_on_latitude"
    t.index ["longitude"], name: "index_streets_on_longitude"
    t.index ["municipality_district_id"], name: "index_streets_on_municipality_district_id"
    t.index ["municipality_id"], name: "index_streets_on_municipality_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "banned", default: false
    t.string "login"
    t.integer "legacy_rights"
    t.string "first_name"
    t.string "last_name"
    t.string "admin_name"
    t.string "phone"
    t.string "email"
    t.string "password"
    t.string "about"
    t.string "logo"
    t.string "website"
    t.boolean "organization"
    t.boolean "anonymous", default: false
    t.boolean "active"
    t.bigint "municipality_id", null: false
    t.boolean "created_from_app", default: false
    t.string "verification"
    t.boolean "verified", default: false
    t.string "signature"
    t.integer "city_id"
    t.bigint "street_id", null: false
    t.boolean "resident"
    t.integer "sex"
    t.date "birth"
    t.string "fcm_token"
    t.boolean "gdpr_accepted"
    t.string "access_token"
    t.integer "exp"
    t.boolean "email_notifiable", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_users_on_active"
    t.index ["anonymous"], name: "index_users_on_anonymous"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["legacy_rights"], name: "index_users_on_legacy_rights"
    t.index ["login"], name: "index_users_on_login"
    t.index ["municipality_id"], name: "index_users_on_municipality_id"
    t.index ["street_id"], name: "index_users_on_street_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "issue_categories", "issue_categories", column: "parent_id"
  add_foreign_key "municipalities", "districts"
  add_foreign_key "municipality_districts", "municipalities"
  add_foreign_key "responsible_subject_categories", "issue_categories"
  add_foreign_key "responsible_subject_categories", "responsible_subjects"
  add_foreign_key "responsible_subjects", "districts"
  add_foreign_key "responsible_subjects", "municipalities"
  add_foreign_key "responsible_subjects", "responsible_subject_types"
  add_foreign_key "streets", "municipalities"
  add_foreign_key "streets", "municipality_districts"
  add_foreign_key "users", "municipalities"
  add_foreign_key "users", "streets"
end
