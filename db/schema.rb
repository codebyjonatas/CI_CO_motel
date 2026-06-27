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

ActiveRecord::Schema[8.1].define(version: 2026_06_19_213629) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "rooms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "daily_rate", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "floor", default: 1
    t.string "number", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["number"], name: "index_rooms_on_number", unique: true
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

  add_foreign_key "stays", "price_periods"
  add_foreign_key "stays", "rooms"
  add_foreign_key "stays", "users"
end
