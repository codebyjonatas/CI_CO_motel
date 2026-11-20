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

ActiveRecord::Schema[8.1].define(version: 2026_11_19_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "cleaning_logs", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.bigint "stay_id"
    t.bigint "cleaned_by_id"
    t.bigint "inspected_by_id"
    t.integer "status"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "inspected_at"
    t.text "notes"
    t.text "rejection_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_cleaning_logs_on_room_id"
    t.index ["stay_id"], name: "index_cleaning_logs_on_stay_id"
  end

  create_table "price_periods", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "duration_minutes", null: false
    t.string "name", null: false
    t.boolean "overnight", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_price_periods_on_code", unique: true
  end

  create_table "product_price_rules", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "priority", default: 0, null: false
    t.integer "days_of_week", default: [], array: true
    t.time "starts_at"
    t.time "ends_at"
    t.date "valid_from"
    t.date "valid_until"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "active", "priority"], name: "idx_on_product_id_active_priority_1078874090"
    t.index ["product_id"], name: "index_product_price_rules_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "code", limit: 20, null: false
    t.string "name", null: false
    t.integer "category", default: 99, null: false
    t.boolean "active", default: true, null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "tax_rate", default: 0, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_products_on_active"
    t.index ["category"], name: "index_products_on_category"
    t.index ["code"], name: "index_products_on_code", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "room_status_logs", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.bigint "stay_id"
    t.bigint "user_id", null: false
    t.integer "from_status", null: false
    t.integer "to_status", null: false
    t.integer "trigger", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id", "created_at"], name: "index_room_status_logs_on_room_id_and_created_at"
    t.index ["room_id"], name: "index_room_status_logs_on_room_id"
    t.index ["stay_id"], name: "index_room_status_logs_on_stay_id"
    t.index ["user_id"], name: "index_room_status_logs_on_user_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "daily_rate", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "floor", default: 1
    t.string "number", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.datetime "cleaning_started_at"
    t.datetime "cleaning_finished_at"
    t.datetime "quarantine_until"
    t.bigint "cleaned_by_id"
    t.index ["cleaned_by_id"], name: "index_rooms_on_cleaned_by_id"
    t.index ["number"], name: "index_rooms_on_number", unique: true
    t.index ["quarantine_until"], name: "index_rooms_on_quarantine_until"
    t.index ["status", "quarantine_until"], name: "index_rooms_on_status_and_quarantine_until", where: "(status = ANY (ARRAY[3, 4]))"
    t.index ["status"], name: "index_rooms_on_status"
  end

  create_table "solid_cache_entries", id: false, force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.timestamp "created_at", null: false
    t.bigint "key_hash", null: false
    t.bigint "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash"
    t.unique_constraint ["key_hash", "byte_size"], name: "solid_cache_entries_key_hash_byte_size_unique"
    t.unique_constraint ["key_hash"], name: "solid_cache_entries_key_hash_unique"
  end

  create_table "solid_cache_keyvaluestores", id: false, force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.timestamp "created_at", null: false
    t.bigint "key_hash", null: false
    t.bigint "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_keyvaluestores_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_keyvaluestores_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_keyvaluestores_on_key_hash"
    t.unique_constraint ["key_hash", "byte_size"], name: "solid_cache_keyvaluestores_key_hash_byte_size_unique"
    t.unique_constraint ["key_hash"], name: "solid_cache_keyvaluestores_key_hash_unique"
  end

  create_table "solid_cache_metadata", id: false, force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.timestamp "created_at", null: false
    t.index ["key"], name: "index_solid_cache_metadata_on_key"
    t.unique_constraint ["key"], name: "solid_cache_metadata_key_unique"
  end

  create_table "stay_audit_logs", force: :cascade do |t|
    t.bigint "stay_id", null: false
    t.bigint "user_id", null: false
    t.string "field_name", null: false
    t.integer "audit_action", default: 0, null: false
    t.text "previous_value"
    t.text "new_value"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_stay_audit_logs_on_created_at"
    t.index ["stay_id"], name: "index_stay_audit_logs_on_stay_id"
    t.index ["user_id"], name: "index_stay_audit_logs_on_user_id"
  end

  create_table "stay_guests", force: :cascade do |t|
    t.bigint "stay_id", null: false
    t.string "full_name", null: false
    t.string "document"
    t.integer "document_type", default: 0, null: false
    t.date "birth_date"
    t.string "phone"
    t.string "email"
    t.boolean "main_guest", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stay_id", "main_guest"], name: "index_stay_guests_on_stay_id_and_main_guest", unique: true, where: "(main_guest = true)"
    t.index ["stay_id"], name: "index_stay_guests_on_stay_id"
  end

  create_table "stays", force: :cascade do |t|
    t.datetime "check_in", null: false
    t.datetime "check_out"
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.text "observation"
    t.bigint "price_period_id", null: false
    t.bigint "room_id", null: false
    t.integer "status", default: 0
    t.decimal "total_value", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "week_number", null: false
    t.index ["price_period_id"], name: "index_stays_on_price_period_id"
    t.index ["room_id"], name: "index_stays_on_room_id"
    t.index ["user_id"], name: "index_stays_on_user_id"
  end

  create_table "tab_item_audits", force: :cascade do |t|
    t.bigint "tab_item_id", null: false
    t.integer "action", null: false
    t.bigint "user_id", null: false
    t.text "reason"
    t.jsonb "previous_state", null: false
    t.integer "tab_status_at_time", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tab_item_id"], name: "index_tab_item_audits_on_tab_item_id"
    t.index ["user_id"], name: "index_tab_item_audits_on_user_id"
  end

  create_table "tab_items", force: :cascade do |t|
    t.bigint "tab_id", null: false
    t.bigint "product_id", null: false
    t.bigint "added_by_id", null: false
    t.bigint "voided_by_id"
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.datetime "voided_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["added_by_id"], name: "index_tab_items_on_added_by_id"
    t.index ["product_id"], name: "index_tab_items_on_product_id"
    t.index ["tab_id"], name: "index_tab_items_on_tab_id"
    t.index ["voided_by_id"], name: "index_tab_items_on_voided_by_id"
  end

  create_table "tabs", force: :cascade do |t|
    t.bigint "stay_id"
    t.bigint "room_id", null: false
    t.bigint "opened_by_id", null: false
    t.bigint "closed_by_id"
    t.string "guest_identifier"
    t.integer "status", default: 0, null: false
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "discount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.text "notes"
    t.datetime "closed_at"
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["closed_by_id"], name: "index_tabs_on_closed_by_id"
    t.index ["opened_by_id"], name: "index_tabs_on_opened_by_id"
    t.index ["room_id", "status"], name: "index_tabs_on_room_id_and_status", where: "(status = ANY (ARRAY[0, 1]))"
    t.index ["room_id"], name: "index_tabs_on_room_id"
    t.index ["stay_id", "status"], name: "index_tabs_on_stay_id_and_status"
    t.index ["stay_id"], name: "index_tabs_on_stay_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "role_id"
    t.bigint "user_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  add_foreign_key "cleaning_logs", "rooms"
  add_foreign_key "cleaning_logs", "stays"
  add_foreign_key "product_price_rules", "products"
  add_foreign_key "room_status_logs", "rooms"
  add_foreign_key "room_status_logs", "stays", on_delete: :nullify
  add_foreign_key "room_status_logs", "users"
  add_foreign_key "rooms", "users", column: "cleaned_by_id"
  add_foreign_key "stay_audit_logs", "stays", name: "stay_audit_logs_stay_id_fkey"
  add_foreign_key "stay_audit_logs", "users", name: "stay_audit_logs_user_id_fkey"
  add_foreign_key "stay_guests", "stays"
  add_foreign_key "stays", "rooms"
  add_foreign_key "stays", "users"
  add_foreign_key "tab_item_audits", "tab_items"
  add_foreign_key "tab_item_audits", "users"
  add_foreign_key "tab_items", "products"
  add_foreign_key "tab_items", "tabs"
  add_foreign_key "tab_items", "users", column: "added_by_id"
  add_foreign_key "tab_items", "users", column: "voided_by_id"
  add_foreign_key "tabs", "rooms"
  add_foreign_key "tabs", "stays"
  add_foreign_key "tabs", "users", column: "closed_by_id"
  add_foreign_key "tabs", "users", column: "opened_by_id"
end
