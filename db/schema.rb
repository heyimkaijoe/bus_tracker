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

ActiveRecord::Schema[7.1].define(version: 2024_07_25_082934) do
  create_table "subscribers", force: :cascade do |t|
    t.string "phone"
    t.string "route"
    t.boolean "route_dir"
    t.integer "target_stop"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
# subscribers table
  # phone
  # route_id
  # route_dir
  # target_stop_seq

# routes table
  # name
  # is_順向

# route_stops table
  # route_id
  # name
  # seq

  Subscriber.where("subscribers.route_id = ?", route.id)
  select * from subscribers where subscribers.route_id = ?

  select subscribers.* from subscribers
  join route_stops on subscribers.route_id = route_stops.route_id
  and route_stops.name = 博仁醫院
  and subscribers.target_stop_seq = route_stops.seq;