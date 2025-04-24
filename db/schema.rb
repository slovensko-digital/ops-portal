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

ActiveRecord::Schema[8.0].define(version: 2025_04_24_082339) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "postgis"
  enable_extension "unaccent"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.integer "position"
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

  create_table "clients", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.string "api_token_public_key"
    t.string "webhook_private_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "responsible_subject_id"
    t.index ["responsible_subject_id"], name: "index_clients_on_responsible_subject_id"
  end

  create_table "cms_categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.bigint "parent_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_category_id", "slug"], name: "index_cms_categories_on_parent_category_id_and_slug", unique: true
  end

  create_table "cms_pages", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.text "text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tags", default: [], array: true
    t.bigint "category_id", null: false
    t.text "raw", null: false
    t.index ["category_id", "slug"], name: "index_cms_pages_on_category_id_and_slug", unique: true
  end

  create_table "connector_activities", force: :cascade do |t|
    t.integer "triage_external_id"
    t.integer "backoffice_external_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "connector_tenant_id", null: false
    t.index ["backoffice_external_id"], name: "index_connector_activities_on_backoffice_external_id"
    t.index ["connector_tenant_id"], name: "index_connector_activities_on_connector_tenant_id"
    t.index ["triage_external_id"], name: "index_connector_activities_on_triage_external_id"
  end

  create_table "connector_issues", force: :cascade do |t|
    t.integer "triage_external_id"
    t.integer "backoffice_external_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "connector_tenant_id", null: false
    t.index ["backoffice_external_id"], name: "index_connector_issues_on_backoffice_external_id"
    t.index ["connector_tenant_id"], name: "index_connector_issues_on_connector_tenant_id"
    t.index ["triage_external_id"], name: "index_connector_issues_on_triage_external_id"
  end

  create_table "connector_tenants", force: :cascade do |t|
    t.string "name"
    t.string "ops_api_token_private_key"
    t.integer "ops_api_subject_identifier"
    t.string "ops_webhook_public_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "backoffice_url"
    t.string "backoffice_api_token"
    t.string "backoffice_webhook_secret"
    t.boolean "receive_customer_activities", default: false, null: false
  end

  create_table "connector_users", force: :cascade do |t|
    t.integer "external_id"
    t.uuid "uuid"
    t.string "firstname"
    t.string "lastname"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "connector_tenant_id", null: false
    t.index ["connector_tenant_id"], name: "index_connector_users_on_connector_tenant_id"
    t.index ["external_id"], name: "index_connector_users_on_external_id"
  end

  create_table "districts", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "legacy_id"
    t.index ["legacy_id"], name: "index_districts_on_legacy_id", unique: true
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

  create_table "issues", force: :cascade do |t|
    t.string "title", null: false
    t.string "description", null: false
    t.datetime "reported_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_synced_at"
    t.integer "triage_external_id"
    t.jsonb "legacy_data"
    t.boolean "anonymous"
    t.float "latitude"
    t.float "longitude"
    t.bigint "author_id"
    t.bigint "category_id", null: false
    t.bigint "state_id"
    t.bigint "municipality_id"
    t.integer "legacy_id"
    t.bigint "municipality_district_id"
    t.bigint "responsible_subject_id"
    t.bigint "subcategory_id"
    t.bigint "subtype_id"
    t.bigint "owner_id"
    t.string "address_region"
    t.string "address_city"
    t.string "address_municipality"
    t.string "address_street"
    t.string "address_house_number"
    t.string "address_postcode"
    t.integer "issue_type", default: 1
    t.string "address_country"
    t.string "address_country_code"
    t.string "address_district"
    t.integer "resolution_external_id"
    t.index "((st_point(longitude, latitude, 4326))::geography)", name: "index_issues_on_location", using: :gist
    t.index ["author_id"], name: "index_issues_on_author_id"
    t.index ["category_id"], name: "index_issues_on_category_id"
    t.index ["legacy_id"], name: "index_issues_on_legacy_id", unique: true
    t.index ["municipality_district_id"], name: "index_issues_on_municipality_district_id"
    t.index ["municipality_id"], name: "index_issues_on_municipality_id"
    t.index ["owner_id"], name: "index_issues_on_owner_id"
    t.index ["responsible_subject_id"], name: "index_issues_on_responsible_subject_id"
    t.index ["state_id"], name: "index_issues_on_state_id"
    t.index ["subcategory_id"], name: "index_issues_on_subcategory_id"
    t.index ["subtype_id"], name: "index_issues_on_subtype_id"
  end

  create_table "issues_activities", force: :cascade do |t|
    t.bigint "issue_id", null: false
    t.string "type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id"], name: "index_issues_activities_on_issue_id"
  end

  create_table "issues_categories", force: :cascade do |t|
    t.string "name"
    t.string "name_hu"
    t.string "alias"
    t.string "description"
    t.string "description_hu"
    t.boolean "catch_all", default: false
    t.integer "weight"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "legacy_id"
    t.integer "triage_external_id"
    t.index ["legacy_id"], name: "index_issues_categories_on_legacy_id", unique: true
  end

  create_table "issues_comments", force: :cascade do |t|
    t.bigint "activity_id", null: false
    t.string "author_name"
    t.string "author_email"
    t.datetime "added_at"
    t.string "text"
    t.inet "ip"
    t.integer "verification"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "legacy_id"
    t.integer "triage_external_id"
    t.bigint "user_author_id"
    t.bigint "agent_author_id"
    t.bigint "responsible_subject_author_id"
    t.boolean "hidden", default: false
    t.jsonb "legacy_data"
    t.string "type"
    t.index ["activity_id"], name: "index_issues_comments_on_activity_id"
    t.index ["agent_author_id"], name: "index_issues_comments_on_agent_author_id"
    t.index ["legacy_id"], name: "index_issues_comments_on_legacy_id", unique: true
    t.index ["responsible_subject_author_id"], name: "index_issues_comments_on_responsible_subject_author_id"
    t.index ["user_author_id"], name: "index_issues_comments_on_user_author_id"
  end

  create_table "issues_drafts", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.boolean "anonymous"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.jsonb "suggestions", default: []
    t.integer "picked_suggestion_index"
    t.jsonb "checks"
    t.string "address_house_number"
    t.string "address_street"
    t.string "address_municipality"
    t.string "address_city"
    t.string "address_postcode"
    t.string "address_country"
    t.string "address_country_code"
    t.bigint "category_id"
    t.bigint "subcategory_id"
    t.bigint "subtype_id"
    t.bigint "author_id", null: false
    t.string "address_region"
    t.boolean "latlon_from_exif", default: false
    t.jsonb "address_data"
    t.string "address_district"
    t.boolean "submitted", default: false, null: false
    t.index ["author_id"], name: "index_issues_drafts_on_author_id"
    t.index ["category_id"], name: "index_issues_drafts_on_category_id"
    t.index ["subcategory_id"], name: "index_issues_drafts_on_subcategory_id"
    t.index ["subtype_id"], name: "index_issues_drafts_on_subtype_id"
  end

  create_table "issues_states", force: :cascade do |t|
    t.string "name"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "legacy_id"
    t.string "key"
    t.index ["legacy_id"], name: "index_issues_states_on_legacy_id", unique: true
  end

  create_table "issues_subcategories", force: :cascade do |t|
    t.string "name"
    t.string "name_hu"
    t.string "alias"
    t.string "description"
    t.string "description_hu"
    t.boolean "catch_all", default: false
    t.integer "weight"
    t.bigint "category_id", null: false
    t.integer "legacy_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_issues_subcategories_on_category_id"
    t.index ["legacy_id"], name: "index_issues_subcategories_on_legacy_id", unique: true
  end

  create_table "issues_subtypes", force: :cascade do |t|
    t.string "name"
    t.string "name_hu"
    t.string "alias"
    t.string "description"
    t.string "description_hu"
    t.boolean "catch_all", default: false
    t.integer "weight"
    t.bigint "subcategory_id", null: false
    t.integer "legacy_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["legacy_id"], name: "index_issues_subtypes_on_legacy_id", unique: true
    t.index ["subcategory_id"], name: "index_issues_subtypes_on_subcategory_id"
  end

  create_table "issues_updates", force: :cascade do |t|
    t.bigint "activity_id", null: false
    t.bigint "author_id"
    t.string "name"
    t.string "email"
    t.string "text"
    t.bigint "confirmed_by_id"
    t.datetime "added_at"
    t.boolean "published"
    t.inet "ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "legacy_id"
    t.integer "triage_external_id"
    t.index ["activity_id"], name: "index_issues_updates_on_activity_id"
    t.index ["author_id"], name: "index_issues_updates_on_author_id"
    t.index ["confirmed_by_id"], name: "index_issues_updates_on_confirmed_by_id"
    t.index ["legacy_id"], name: "index_issues_updates_on_legacy_id", unique: true
  end

  create_table "legacy_agents", force: :cascade do |t|
    t.string "email"
    t.string "firstname"
    t.string "lastname"
    t.integer "legacy_id"
    t.integer "external_id"
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "banned", default: false
    t.string "login"
    t.integer "rights"
    t.string "admin_name"
    t.string "phone"
    t.string "password_hash"
    t.string "about"
    t.boolean "organization"
    t.datetime "timestamp"
    t.boolean "anonymous", default: false
    t.boolean "active"
    t.bigint "municipality_id"
    t.boolean "created_from_app", default: false
    t.string "verification"
    t.boolean "verified", default: false
    t.string "signature"
    t.integer "city_id"
    t.bigint "street_id"
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
    t.string "display_name"
    t.index ["external_id"], name: "index_legacy_agents_on_external_id", unique: true
    t.index ["municipality_id"], name: "index_legacy_agents_on_municipality_id"
    t.index ["street_id"], name: "index_legacy_agents_on_street_id"
  end

  create_table "legacy_issues_communications", force: :cascade do |t|
    t.bigint "activity_id", null: false
    t.boolean "from_responsible_subject"
    t.string "subject"
    t.string "message"
    t.integer "admin_id"
    t.integer "person_id"
    t.integer "user_id"
    t.string "text"
    t.string "solved_by"
    t.string "solved_in"
    t.boolean "solved"
    t.boolean "solution_rejected"
    t.string "email"
    t.datetime "added_at"
    t.inet "ip"
    t.boolean "internal"
    t.boolean "confirmation_needed"
    t.string "plain_message"
    t.string "signature"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "legacy_id"
    t.integer "triage_external_id"
    t.bigint "agent_author_id"
    t.bigint "responsible_subjects_user_author_id"
    t.string "type"
    t.index ["activity_id"], name: "index_legacy_issues_communications_on_activity_id"
    t.index ["agent_author_id"], name: "index_legacy_issues_communications_on_agent_author_id"
    t.index ["legacy_id"], name: "index_legacy_issues_communications_on_legacy_id", unique: true
    t.index ["responsible_subjects_user_author_id"], name: "idx_on_responsible_subjects_user_author_id_dc50bfe063"
  end

  create_table "municipalities", force: :cascade do |t|
    t.string "name"
    t.bigint "district_id"
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
    t.integer "legacy_id"
    t.index ["active"], name: "index_municipalities_on_active"
    t.index ["alias"], name: "index_municipalities_on_alias"
    t.index ["district_id"], name: "index_municipalities_on_district_id"
    t.index ["latitude"], name: "index_municipalities_on_latitude"
    t.index ["legacy_id"], name: "index_municipalities_on_legacy_id", unique: true
    t.index ["longitude"], name: "index_municipalities_on_longitude"
  end

  create_table "municipality_districts", force: :cascade do |t|
    t.string "name"
    t.bigint "municipality_id", null: false
    t.string "alias"
    t.string "genitiv"
    t.string "lokal"
    t.string "description"
    t.string "logo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "legacy_id"
    t.index ["legacy_id"], name: "index_municipality_districts_on_legacy_id", unique: true
    t.index ["municipality_id"], name: "index_municipality_districts_on_municipality_id"
  end

  create_table "responsible_subjects", force: :cascade do |t|
    t.bigint "district_id"
    t.bigint "municipality_id"
    t.bigint "responsible_subjects_type_id", null: false
    t.bigint "municipality_district_id"
    t.integer "scope"
    t.string "subject_name"
    t.string "email"
    t.string "name"
    t.string "code"
    t.boolean "active"
    t.boolean "pro"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "legacy_id"
    t.string "external_id"
    t.index ["district_id"], name: "index_responsible_subjects_on_district_id"
    t.index ["legacy_id"], name: "index_responsible_subjects_on_legacy_id", unique: true
    t.index ["municipality_district_id"], name: "index_responsible_subjects_on_municipality_district_id"
    t.index ["municipality_id"], name: "index_responsible_subjects_on_municipality_id"
    t.index ["responsible_subjects_type_id"], name: "index_responsible_subjects_on_responsible_subjects_type_id"
  end

  create_table "responsible_subjects_categories", force: :cascade do |t|
    t.bigint "responsible_subject_id"
    t.bigint "issues_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "legacy_id"
    t.bigint "issues_subcategory_id"
    t.bigint "issues_subtype_id"
    t.index ["issues_category_id"], name: "index_responsible_subjects_categories_on_issues_category_id"
    t.index ["issues_subcategory_id"], name: "index_responsible_subjects_categories_on_issues_subcategory_id"
    t.index ["issues_subtype_id"], name: "index_responsible_subjects_categories_on_issues_subtype_id"
    t.index ["legacy_id"], name: "index_responsible_subjects_categories_on_legacy_id", unique: true
    t.index ["responsible_subject_id"], name: "idx_on_responsible_subject_id_7ec5499a35"
  end

  create_table "responsible_subjects_organization_units", force: :cascade do |t|
    t.bigint "responsible_subject_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "legacy_id"
    t.index ["legacy_id"], name: "index_responsible_subjects_organization_units_on_legacy_id", unique: true
    t.index ["responsible_subject_id"], name: "idx_on_responsible_subject_id_f2ce80d659"
  end

  create_table "responsible_subjects_types", force: :cascade do |t|
    t.string "name"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "legacy_id"
    t.index ["legacy_id"], name: "index_responsible_subjects_types_on_legacy_id", unique: true
  end

  create_table "responsible_subjects_user_roles", force: :cascade do |t|
    t.string "slug"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "legacy_id"
    t.index ["legacy_id"], name: "index_responsible_subjects_user_roles_on_legacy_id", unique: true
  end

  create_table "responsible_subjects_users", force: :cascade do |t|
    t.bigint "responsible_subject_id"
    t.bigint "role_id", null: false
    t.string "login"
    t.string "password"
    t.string "name"
    t.string "email"
    t.string "token"
    t.string "photo"
    t.datetime "deleted_at"
    t.bigint "organization_unit_id"
    t.boolean "gdpr_accepted"
    t.boolean "tooltips"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "legacy_id"
    t.index ["legacy_id"], name: "index_responsible_subjects_users_on_legacy_id", unique: true
    t.index ["organization_unit_id"], name: "index_responsible_subjects_users_on_organization_unit_id"
    t.index ["responsible_subject_id"], name: "index_responsible_subjects_users_on_responsible_subject_id"
    t.index ["role_id"], name: "index_responsible_subjects_users_on_role_id"
  end

  create_table "streets", force: :cascade do |t|
    t.string "name"
    t.bigint "municipality_id", null: false
    t.bigint "municipality_district_id"
    t.string "place_identifier"
    t.float "latitude"
    t.float "longitude"
    t.boolean "tested"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "legacy_id"
    t.index ["latitude"], name: "index_streets_on_latitude"
    t.index ["legacy_id"], name: "index_streets_on_legacy_id", unique: true
    t.index ["longitude"], name: "index_streets_on_longitude"
    t.index ["municipality_district_id"], name: "index_streets_on_municipality_district_id"
    t.index ["municipality_id"], name: "index_streets_on_municipality_id"
  end

  create_table "user_identities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.index ["provider", "uid"], name: "index_user_identities_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_user_identities_on_user_id"
  end

  create_table "user_login_change_keys", force: :cascade do |t|
    t.string "key", null: false
    t.string "login", null: false
    t.datetime "deadline", null: false
  end

  create_table "user_password_reset_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "user_remember_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
  end

  create_table "user_verification_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "requested_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "users", force: :cascade do |t|
    t.citext "email", null: false
    t.string "firstname"
    t.string "lastname"
    t.integer "external_id"
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "banned", default: false
    t.string "login"
    t.string "admin_name"
    t.string "phone"
    t.string "password_hash"
    t.string "about"
    t.boolean "organization"
    t.datetime "timestamp"
    t.boolean "anonymous", default: false
    t.boolean "active"
    t.bigint "municipality_id"
    t.boolean "created_from_app", default: false
    t.string "verification"
    t.boolean "verified", default: false
    t.string "signature"
    t.integer "city_id"
    t.bigint "street_id"
    t.boolean "resident"
    t.integer "sex"
    t.date "birth"
    t.string "fcm_token"
    t.boolean "gdpr_accepted"
    t.string "access_token"
    t.integer "exp"
    t.boolean "email_notifiable", default: true
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "legacy_id"
    t.integer "status", default: 1, null: false
    t.string "display_name"
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(status = ANY (ARRAY[1, 2]))"
    t.index ["external_id"], name: "index_users_on_external_id", unique: true
    t.index ["legacy_id"], name: "index_users_on_legacy_id", unique: true
    t.index ["municipality_id"], name: "index_users_on_municipality_id"
    t.index ["street_id"], name: "index_users_on_street_id"
    t.check_constraint "email ~ '^[^,;@ \r\n]+@[^,@; \r\n]+\\.[^,@; \r\n]+$'::citext", name: "valid_email"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "clients", "responsible_subjects"
  add_foreign_key "cms_categories", "cms_categories", column: "parent_category_id"
  add_foreign_key "cms_pages", "cms_categories", column: "category_id", on_delete: :cascade
  add_foreign_key "connector_activities", "connector_tenants"
  add_foreign_key "connector_issues", "connector_tenants"
  add_foreign_key "connector_users", "connector_tenants"
  add_foreign_key "issues", "issues_categories", column: "category_id"
  add_foreign_key "issues", "issues_states", column: "state_id"
  add_foreign_key "issues", "issues_subcategories", column: "subcategory_id"
  add_foreign_key "issues", "issues_subtypes", column: "subtype_id"
  add_foreign_key "issues", "legacy_agents", column: "owner_id"
  add_foreign_key "issues", "municipality_districts"
  add_foreign_key "issues", "responsible_subjects"
  add_foreign_key "issues", "users", column: "author_id"
  add_foreign_key "issues_activities", "issues"
  add_foreign_key "issues_comments", "issues_activities", column: "activity_id"
  add_foreign_key "issues_comments", "legacy_agents", column: "agent_author_id"
  add_foreign_key "issues_comments", "responsible_subjects", column: "responsible_subject_author_id"
  add_foreign_key "issues_comments", "users", column: "user_author_id"
  add_foreign_key "issues_drafts", "issues_categories", column: "category_id"
  add_foreign_key "issues_drafts", "issues_subcategories", column: "subcategory_id"
  add_foreign_key "issues_drafts", "issues_subtypes", column: "subtype_id"
  add_foreign_key "issues_drafts", "users", column: "author_id"
  add_foreign_key "issues_subcategories", "issues_categories", column: "category_id"
  add_foreign_key "issues_subtypes", "issues_subcategories", column: "subcategory_id"
  add_foreign_key "issues_updates", "issues_activities", column: "activity_id"
  add_foreign_key "issues_updates", "users", column: "author_id"
  add_foreign_key "issues_updates", "users", column: "confirmed_by_id"
  add_foreign_key "legacy_agents", "municipalities"
  add_foreign_key "legacy_agents", "streets"
  add_foreign_key "legacy_issues_communications", "issues_activities", column: "activity_id"
  add_foreign_key "legacy_issues_communications", "legacy_agents", column: "agent_author_id"
  add_foreign_key "legacy_issues_communications", "responsible_subjects_users", column: "responsible_subjects_user_author_id"
  add_foreign_key "municipalities", "districts"
  add_foreign_key "municipality_districts", "municipalities"
  add_foreign_key "responsible_subjects", "districts"
  add_foreign_key "responsible_subjects", "municipalities"
  add_foreign_key "responsible_subjects", "municipality_districts"
  add_foreign_key "responsible_subjects", "responsible_subjects_types"
  add_foreign_key "responsible_subjects_categories", "issues_categories"
  add_foreign_key "responsible_subjects_categories", "responsible_subjects"
  add_foreign_key "responsible_subjects_organization_units", "responsible_subjects"
  add_foreign_key "responsible_subjects_users", "responsible_subjects"
  add_foreign_key "responsible_subjects_users", "responsible_subjects_organization_units", column: "organization_unit_id"
  add_foreign_key "responsible_subjects_users", "responsible_subjects_user_roles", column: "role_id"
  add_foreign_key "streets", "municipalities"
  add_foreign_key "streets", "municipality_districts"
  add_foreign_key "user_identities", "users", on_delete: :cascade
  add_foreign_key "user_login_change_keys", "users", column: "id"
  add_foreign_key "user_password_reset_keys", "users", column: "id"
  add_foreign_key "user_remember_keys", "users", column: "id"
  add_foreign_key "user_verification_keys", "users", column: "id"
  add_foreign_key "users", "municipalities"
  add_foreign_key "users", "streets"
end
