# frozen_string_literal: true

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

ActiveRecord::Schema.define(version: 2021_04_19_192702) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounting_accounts", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "qb_account_classification"
    t.string "qb_id", null: false
    t.json "quickbooks_data"
    t.datetime "updated_at", null: false
    t.index ["qb_id"], name: "index_accounting_accounts_on_qb_id"
  end

  create_table "accounting_customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "qb_id", null: false
    t.json "quickbooks_data"
    t.datetime "updated_at", null: false
  end

  create_table "accounting_line_items", id: :serial, force: :cascade do |t|
    t.integer "accounting_account_id", null: false
    t.integer "accounting_transaction_id", null: false
    t.decimal "amount", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.string "posting_type", null: false
    t.integer "qb_line_id"
    t.datetime "updated_at", null: false
    t.index ["accounting_account_id"], name: "index_accounting_line_items_on_accounting_account_id"
    t.index ["accounting_transaction_id"], name: "index_accounting_line_items_on_accounting_transaction_id"
  end

  create_table "accounting_problem_loan_transactions", force: :cascade do |t|
    t.bigint "accounting_transaction_id"
    t.datetime "created_at", null: false
    t.json "custom_data"
    t.string "level"
    t.string "message", null: false
    t.bigint "project_id"
    t.datetime "updated_at", null: false
    t.index ["accounting_transaction_id"], name: "index_plt_on_txn_id"
    t.index ["project_id"], name: "index_accounting_problem_loan_transactions_on_project_id"
  end

  create_table "accounting_qb_connections", id: :serial, force: :cascade do |t|
    t.string "access_token"
    t.datetime "created_at", null: false
    t.integer "division_id", null: false
    t.datetime "last_updated_at"
    t.string "realm_id", null: false
    t.string "refresh_token"
    t.datetime "token_expires_at", null: false
    t.datetime "updated_at", null: false
    t.index ["division_id"], name: "index_accounting_qb_connections_on_division_id"
  end

  create_table "accounting_qb_departments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "division_id"
    t.string "name", null: false
    t.string "qb_id", null: false
    t.json "quickbooks_data"
    t.datetime "updated_at", null: false
    t.index ["division_id"], name: "index_accounting_qb_departments_on_division_id"
  end

  create_table "accounting_qb_vendors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "qb_id", null: false
    t.json "quickbooks_data"
    t.datetime "updated_at", null: false
  end

  create_table "accounting_transactions", id: :serial, force: :cascade do |t|
    t.integer "accounting_account_id"
    t.string "accounting_customer_id"
    t.decimal "amount"
    t.decimal "change_in_interest", precision: 15, scale: 2
    t.decimal "change_in_principal", precision: 15, scale: 2
    t.string "check_number"
    t.datetime "created_at", null: false
    t.integer "currency_id"
    t.string "description"
    t.decimal "interest_balance", default: "0.0"
    t.string "loan_transaction_type_value"
    t.boolean "managed", default: false, null: false
    t.boolean "needs_qb_push", default: true, null: false
    t.decimal "principal_balance", default: "0.0"
    t.string "private_note"
    t.integer "project_id"
    t.string "qb_id"
    t.string "qb_object_subtype"
    t.string "qb_object_type", default: "JournalEntry", null: false
    t.integer "qb_vendor_id"
    t.json "quickbooks_data"
    t.string "sync_token"
    t.decimal "total"
    t.date "txn_date"
    t.datetime "updated_at", null: false
    t.index ["accounting_account_id"], name: "index_accounting_transactions_on_accounting_account_id"
    t.index ["currency_id"], name: "index_accounting_transactions_on_currency_id"
    t.index ["project_id"], name: "index_accounting_transactions_on_project_id"
    t.index ["qb_id", "qb_object_type"], name: "index_accounting_transactions_on_qb_id_and_qb_object_type", unique: true
    t.index ["qb_id"], name: "index_accounting_transactions_on_qb_id"
    t.index ["qb_object_type"], name: "index_accounting_transactions_on_qb_object_type"
  end

  create_table "countries", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "default_currency_id", null: false
    t.string "iso_code", limit: 2, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "currencies", id: :serial, force: :cascade do |t|
    t.string "code"
    t.string "country_code"
    t.datetime "created_at", null: false
    t.string "name"
    t.string "short_symbol"
    t.string "symbol"
    t.datetime "updated_at", null: false
  end

  create_table "data_exports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data"
    t.bigint "division_id", null: false
    t.datetime "end_date"
    t.string "locale_code", null: false
    t.string "name", null: false
    t.datetime "start_date"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["division_id"], name: "index_data_exports_on_division_id"
  end

  create_table "division_hierarchies", id: false, force: :cascade do |t|
    t.integer "ancestor_id", null: false
    t.integer "descendant_id", null: false
    t.integer "generations", null: false
    t.index ["ancestor_id", "descendant_id", "generations"], name: "division_anc_desc_idx", unique: true
    t.index ["descendant_id"], name: "division_desc_idx"
  end

  create_table "divisions", id: :serial, force: :cascade do |t|
    t.string "accent_fg_color"
    t.string "accent_main_color"
    t.string "banner_bg_color"
    t.string "banner_fg_color"
    t.date "closed_books_date"
    t.datetime "created_at", null: false
    t.integer "currency_id"
    t.json "custom_data"
    t.text "description"
    t.integer "interest_income_account_id"
    t.integer "interest_receivable_account_id"
    t.string "internal_name"
    t.json "locales"
    t.string "logo"
    t.string "logo_content_type"
    t.string "logo_file_name"
    t.integer "logo_file_size"
    t.string "logo_text"
    t.datetime "logo_updated_at"
    t.string "name"
    t.boolean "notify_on_new_logs", default: false
    t.integer "organization_id"
    t.integer "parent_id"
    t.integer "principal_account_id"
    t.boolean "public", default: false, null: false
    t.string "qb_parent_class_id"
    t.boolean "qb_read_only", default: true, null: false
    t.string "short_name"
    t.datetime "updated_at", null: false
    t.index ["currency_id"], name: "index_divisions_on_currency_id"
    t.index ["interest_income_account_id"], name: "index_divisions_on_interest_income_account_id"
    t.index ["interest_receivable_account_id"], name: "index_divisions_on_interest_receivable_account_id"
    t.index ["organization_id"], name: "index_divisions_on_organization_id"
    t.index ["principal_account_id"], name: "index_divisions_on_principal_account_id"
    t.index ["short_name"], name: "index_divisions_on_short_name", unique: true
  end

  create_table "documentations", force: :cascade do |t|
    t.string "calling_action"
    t.string "calling_controller"
    t.datetime "created_at", null: false
    t.bigint "division_id"
    t.string "html_identifier"
    t.datetime "updated_at", null: false
    t.index ["division_id"], name: "index_documentations_on_division_id"
    t.index ["html_identifier"], name: "index_documentations_on_html_identifier", unique: true
  end

  create_table "loan_health_checks", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "has_late_steps"
    t.boolean "has_sporadic_updates"
    t.date "last_log_date"
    t.integer "loan_id", null: false
    t.boolean "missing_contract"
    t.decimal "progress_pct"
    t.datetime "updated_at", null: false
    t.index ["loan_id"], name: "index_loan_health_checks_on_loan_id"
  end

  create_table "loan_question_requirements", id: :serial, force: :cascade do |t|
    t.decimal "amount"
    t.integer "option_id"
    t.integer "question_id"
  end

  create_table "media", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "featured", default: false, null: false
    t.string "item"
    t.string "item_content_type"
    t.integer "item_file_size"
    t.integer "item_height"
    t.integer "item_width"
    t.string "kind_value"
    t.integer "media_attachable_id"
    t.string "media_attachable_type"
    t.integer "sort_order"
    t.datetime "updated_at", null: false
    t.integer "uploader_id"
    t.index ["media_attachable_type", "media_attachable_id"], name: "index_media_on_media_attachable_type_and_media_attachable_id"
  end

  create_table "notes", id: :serial, force: :cascade do |t|
    t.integer "author_id"
    t.datetime "created_at", null: false
    t.integer "notable_id"
    t.string "notable_type"
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_notes_on_author_id"
    t.index ["notable_type", "notable_id"], name: "index_notes_on_notable_type_and_notable_id"
  end

  create_table "option_sets", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "division_id", null: false
    t.string "model_attribute"
    t.string "model_type"
    t.datetime "updated_at", null: false
    t.index ["division_id"], name: "index_option_sets_on_division_id"
  end

  create_table "options", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "migration_id"
    t.integer "option_set_id"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["option_set_id"], name: "index_options_on_option_set_id"
    t.index ["value"], name: "index_options_on_value"
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.string "alias"
    t.string "city"
    t.text "contact_notes"
    t.integer "country_id", null: false
    t.datetime "created_at", null: false
    t.json "custom_data"
    t.integer "division_id"
    t.string "email"
    t.string "fax"
    t.string "industry"
    t.boolean "is_recovered"
    t.string "last_name"
    t.string "legal_name"
    t.string "name"
    t.string "neighborhood"
    t.string "postal_code"
    t.integer "primary_contact_id"
    t.string "primary_phone"
    t.string "referral_source"
    t.string "secondary_phone"
    t.string "sector"
    t.string "state"
    t.text "street_address"
    t.string "tax_no"
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["division_id"], name: "index_organizations_on_division_id"
  end

  create_table "people", id: :serial, force: :cascade do |t|
    t.date "birth_date"
    t.string "city"
    t.text "contact_notes"
    t.integer "country_id"
    t.datetime "created_at", null: false
    t.integer "division_id"
    t.string "email"
    t.string "fax"
    t.string "first_name"
    t.boolean "has_system_access", default: false, null: false
    t.string "last_name"
    t.integer "legacy_id"
    t.string "legal_name"
    t.string "name"
    t.string "neighborhood"
    t.string "postal_code"
    t.integer "primary_organization_id"
    t.string "primary_phone"
    t.string "secondary_phone"
    t.string "state"
    t.text "street_address"
    t.string "tax_no"
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["division_id"], name: "index_people_on_division_id"
  end

  create_table "project_logs", id: :serial, force: :cascade do |t|
    t.integer "agent_id"
    t.datetime "created_at", null: false
    t.date "date"
    t.date "date_changed_to"
    t.string "progress_metric_value"
    t.integer "project_step_id"
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_project_logs_on_agent_id"
    t.index ["project_step_id"], name: "index_project_logs_on_project_step_id"
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.date "actual_end_date"
    t.date "actual_first_interest_payment_date"
    t.date "actual_first_payment_date"
    t.decimal "actual_return"
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.integer "currency_id"
    t.json "custom_data"
    t.integer "division_id", null: false
    t.integer "length_months"
    t.string "loan_type_value"
    t.string "name"
    t.integer "organization_id"
    t.integer "original_id"
    t.integer "primary_agent_id"
    t.date "projected_end_date"
    t.date "projected_first_interest_payment_date"
    t.date "projected_first_payment_date"
    t.decimal "projected_return"
    t.string "public_level_value", null: false
    t.decimal "rate"
    t.integer "representative_id"
    t.integer "secondary_agent_id"
    t.date "signing_date"
    t.string "status_value"
    t.string "txn_handling_mode", default: "automatic", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_id"], name: "index_projects_on_currency_id"
    t.index ["division_id"], name: "index_projects_on_division_id"
    t.index ["organization_id"], name: "index_projects_on_organization_id"
  end

  create_table "question_hierarchies", id: false, force: :cascade do |t|
    t.integer "ancestor_id", null: false
    t.integer "descendant_id", null: false
    t.integer "generations", null: false
    t.index ["ancestor_id", "descendant_id", "generations"], name: "custom_field_anc_desc_idx", unique: true
    t.index ["descendant_id"], name: "custom_field_desc_idx"
  end

  create_table "question_sets", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "internal_name"
    t.datetime "updated_at", null: false
  end

  create_table "questions", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "data_type", null: false
    t.boolean "display_in_summary", default: false, null: false
    t.integer "division_id", null: false
    t.boolean "has_embeddable_media", default: false, null: false
    t.string "internal_name"
    t.integer "migration_position"
    t.integer "number"
    t.boolean "override_associations", default: false, null: false
    t.integer "parent_id"
    t.integer "position"
    t.integer "question_set_id"
    t.boolean "required", default: false, null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["question_set_id"], name: "index_questions_on_question_set_id"
  end

  create_table "response_sets", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "custom_data"
    t.string "kind"
    t.integer "loan_id", null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "updater_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.string "name", null: false
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "updated_at"
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", unique: true
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "tasks", force: :cascade do |t|
    t.json "activity_message_data"
    t.string "activity_message_value", limit: 65536, null: false
    t.datetime "created_at", null: false
    t.json "custom_error_data"
    t.string "job_class", limit: 255, null: false
    t.datetime "job_first_started_at"
    t.datetime "job_last_failed_at"
    t.datetime "job_succeeded_at"
    t.string "job_type_value", limit: 255, null: false
    t.integer "num_attempts", default: 0, null: false
    t.string "provider_job_id"
    t.bigint "taskable_id"
    t.string "taskable_type"
    t.datetime "updated_at", null: false
    t.index ["taskable_type", "taskable_id"], name: "index_tasks_on_taskable_type_and_taskable_id"
  end

  create_table "timeline_entries", id: :serial, force: :cascade do |t|
    t.date "actual_end_date"
    t.integer "agent_id"
    t.datetime "created_at", null: false
    t.integer "date_change_count", default: 0, null: false
    t.datetime "finalized_at"
    t.boolean "is_finalized"
    t.integer "old_duration_days", default: 0
    t.date "old_start_date"
    t.integer "parent_id"
    t.integer "project_id"
    t.integer "schedule_parent_id"
    t.integer "scheduled_duration_days"
    t.date "scheduled_start_date"
    t.string "step_type_value", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_timeline_entries_on_agent_id"
    t.index ["project_id"], name: "index_timeline_entries_on_project_id"
  end

  create_table "timeline_entry_hierarchies", id: false, force: :cascade do |t|
    t.integer "ancestor_id", null: false
    t.integer "descendant_id", null: false
    t.integer "generations", null: false
    t.index ["ancestor_id", "descendant_id", "generations"], name: "timeline_entry_anc_desc_idx", unique: true
    t.index ["descendant_id"], name: "timeline_entry_desc_idx"
  end

  create_table "translations", id: :serial, force: :cascade do |t|
    t.boolean "allow_html", default: false
    t.datetime "created_at"
    t.string "locale"
    t.text "text"
    t.string "translatable_attribute"
    t.integer "translatable_id"
    t.string "translatable_type"
    t.datetime "updated_at"
    t.index ["translatable_type", "translatable_id"], name: "index_translations_on_translatable_type_and_translatable_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.inet "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.inet "last_sign_in_ip"
    t.boolean "notify_on_new_logs", default: true
    t.integer "profile_id"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["profile_id"], name: "index_users_on_profile_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "role_id"
    t.integer "user_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", unique: true
  end

  add_foreign_key "accounting_line_items", "accounting_accounts"
  add_foreign_key "accounting_line_items", "accounting_transactions"
  add_foreign_key "accounting_problem_loan_transactions", "accounting_transactions"
  add_foreign_key "accounting_problem_loan_transactions", "projects"
  add_foreign_key "accounting_qb_connections", "divisions"
  add_foreign_key "accounting_qb_departments", "divisions"
  add_foreign_key "accounting_transactions", "accounting_accounts"
  add_foreign_key "accounting_transactions", "currencies"
  add_foreign_key "accounting_transactions", "projects"
  add_foreign_key "countries", "currencies", column: "default_currency_id"
  add_foreign_key "data_exports", "divisions"
  add_foreign_key "divisions", "accounting_accounts", column: "interest_income_account_id"
  add_foreign_key "divisions", "accounting_accounts", column: "interest_receivable_account_id"
  add_foreign_key "divisions", "accounting_accounts", column: "principal_account_id"
  add_foreign_key "divisions", "currencies"
  add_foreign_key "divisions", "organizations"
  add_foreign_key "documentations", "divisions"
  add_foreign_key "loan_health_checks", "projects", column: "loan_id"
  add_foreign_key "media", "people", column: "uploader_id"
  add_foreign_key "option_sets", "divisions"
  add_foreign_key "options", "option_sets"
  add_foreign_key "organizations", "countries"
  add_foreign_key "organizations", "divisions"
  add_foreign_key "organizations", "people", column: "primary_contact_id"
  add_foreign_key "people", "countries"
  add_foreign_key "people", "divisions"
  add_foreign_key "people", "organizations", column: "primary_organization_id"
  add_foreign_key "project_logs", "people", column: "agent_id"
  add_foreign_key "project_logs", "timeline_entries", column: "project_step_id"
  add_foreign_key "projects", "currencies"
  add_foreign_key "projects", "divisions"
  add_foreign_key "projects", "organizations"
  add_foreign_key "projects", "people", column: "primary_agent_id"
  add_foreign_key "projects", "people", column: "representative_id"
  add_foreign_key "projects", "people", column: "secondary_agent_id"
  add_foreign_key "questions", "question_sets"
  add_foreign_key "response_sets", "users", column: "updater_id"
  add_foreign_key "timeline_entries", "people", column: "agent_id"
  add_foreign_key "timeline_entries", "projects"
  add_foreign_key "timeline_entries", "timeline_entries", column: "parent_id"
  add_foreign_key "timeline_entries", "timeline_entries", column: "schedule_parent_id"
  add_foreign_key "users", "people", column: "profile_id"
  add_foreign_key "users_roles", "roles"
  add_foreign_key "users_roles", "users"
end
