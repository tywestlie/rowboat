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

ActiveRecord::Schema[8.1].define(version: 2026_08_04_213206) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "boats", force: :cascade do |t|
    t.string "boat_type"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "home_port"
    t.decimal "length_feet"
    t.string "name"
    t.bigint "owner_id", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_boats_on_owner_id"
  end

  create_table "crew_memberships", force: :cascade do |t|
    t.bigint "boat_id", null: false
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["boat_id"], name: "index_crew_memberships_on_boat_id"
    t.index ["user_id", "boat_id"], name: "index_crew_memberships_on_user_id_and_boat_id", unique: true
    t.index ["user_id"], name: "index_crew_memberships_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "email"
    t.integer "experience_level"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "boats", "users", column: "owner_id"
  add_foreign_key "crew_memberships", "boats"
  add_foreign_key "crew_memberships", "users"
end
