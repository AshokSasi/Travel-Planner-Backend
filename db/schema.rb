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

ActiveRecord::Schema[7.1].define(version: 2026_03_09_015702) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "categories", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.string "name"
    t.string "color", null: false
    t.float "x", default: 0.0
    t.float "y", default: 0.0
    t.float "width", default: 350.0
    t.float "height", default: 350.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["trip_id"], name: "index_categories_on_trip_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 10, scale: 2
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["trip_id"], name: "index_expenses_on_trip_id"
    t.index ["user_id"], name: "index_expenses_on_user_id"
  end

  create_table "idea_cards", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.float "x"
    t.float "y"
    t.bigint "trip_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.integer "upvotes", default: 0
    t.string "url"
    t.string "image"
    t.index ["trip_id"], name: "index_idea_cards_on_trip_id"
  end

  create_table "idea_upvotes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "idea_card_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["idea_card_id"], name: "index_idea_upvotes_on_idea_card_id"
    t.index ["user_id", "idea_card_id"], name: "index_idea_upvotes_on_user_id_and_idea_card_id", unique: true
    t.index ["user_id"], name: "index_idea_upvotes_on_user_id"
  end

  create_table "itinerary_days", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.date "date"
    t.integer "day_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "city"
    t.string "accomodation_name"
    t.string "accomodation_address"
    t.index ["trip_id"], name: "index_itinerary_days_on_trip_id"
  end

  create_table "itinerary_items", force: :cascade do |t|
    t.bigint "itinerary_day_id"
    t.bigint "idea_card_id", null: false
    t.string "title"
    t.text "notes"
    t.integer "order_index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.time "scheduled_time"
    t.string "time_of_day"
    t.index ["idea_card_id"], name: "index_itinerary_items_on_idea_card_id"
    t.index ["itinerary_day_id"], name: "index_itinerary_items_on_itinerary_day_id"
  end

  create_table "settlements", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.bigint "user_id", null: false
    t.bigint "receiver_id"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["receiver_id"], name: "index_settlements_on_receiver_id"
    t.index ["trip_id"], name: "index_settlements_on_trip_id"
    t.index ["user_id"], name: "index_settlements_on_user_id"
  end

  create_table "tests", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trip_members", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "trip_id", null: false
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["trip_id"], name: "index_trip_members_on_trip_id"
    t.index ["user_id"], name: "index_trip_members_on_user_id"
  end

  create_table "trips", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location"
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.string "invite_token"
    t.datetime "invite_expires_at"
    t.string "image_url"
    t.boolean "is_template", default: false
    t.string "template_description"
    t.string "template_tags", default: [], array: true
    t.integer "duplicate_count", default: 0
    t.datetime "published_at"
    t.index ["invite_token"], name: "index_trips_on_invite_token"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "name", null: false
    t.boolean "onboarding_complete", default: false, null: false
    t.boolean "tutorial_complete", default: false, null: false
    t.string "google_avatar_url"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "categories", "trips"
  add_foreign_key "expenses", "trips"
  add_foreign_key "expenses", "users"
  add_foreign_key "idea_cards", "trips"
  add_foreign_key "idea_upvotes", "idea_cards"
  add_foreign_key "idea_upvotes", "users"
  add_foreign_key "itinerary_days", "trips"
  add_foreign_key "itinerary_items", "idea_cards"
  add_foreign_key "itinerary_items", "itinerary_days"
  add_foreign_key "settlements", "trips"
  add_foreign_key "settlements", "users"
  add_foreign_key "settlements", "users", column: "receiver_id"
  add_foreign_key "trip_members", "trips"
  add_foreign_key "trip_members", "users"
end
