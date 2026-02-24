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

ActiveRecord::Schema[7.1].define(version: 2026_02_24_022622) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "itinerary_days", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.date "date"
    t.integer "day_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["idea_card_id"], name: "index_itinerary_items_on_idea_card_id"
    t.index ["itinerary_day_id"], name: "index_itinerary_items_on_itinerary_day_id"
  end

  create_table "tests", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trips", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location"
    t.date "start_date", null: false
    t.date "end_date", null: false
  end

  add_foreign_key "idea_cards", "trips"
  add_foreign_key "itinerary_days", "trips"
  add_foreign_key "itinerary_items", "idea_cards"
  add_foreign_key "itinerary_items", "itinerary_days"
end
