# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150604194247) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "agencies", force: true do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "configurables", force: true do |t|
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "configurables", ["name"], name: "index_configurables_on_name", using: :btree

  create_table "equipment_sets", force: true do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "event_trees", force: true do |t|
    t.integer  "event_id"
    t.integer  "tree_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "event_trees", ["event_id"], name: "index_event_trees_on_event_id", using: :btree
  add_index "event_trees", ["tree_id"], name: "index_event_trees_on_tree_id", using: :btree

  create_table "event_users", force: true do |t|
    t.integer  "event_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status"
  end

  add_index "event_users", ["event_id"], name: "index_event_users_on_event_id", using: :btree
  add_index "event_users", ["user_id"], name: "index_event_users_on_user_id", using: :btree

  create_table "events", force: true do |t|
    t.datetime "start"
    t.datetime "finish"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.text     "description"
    t.integer  "coordinator_id"
    t.text     "notes"
    t.integer  "status",                                         default: 0
    t.text     "address"
    t.decimal  "lat",                    precision: 9, scale: 6
    t.decimal  "lng",                    precision: 9, scale: 6
    t.integer  "min",                                            default: 0
    t.integer  "max"
    t.boolean  "hide_specific_location",                         default: true
    t.boolean  "below_min",                                      default: false
    t.boolean  "reached_max",                                    default: false
    t.integer  "ward_id"
    t.integer  "equipment_set_id"
    t.integer  "agency_id"
  end

  add_index "events", ["coordinator_id"], name: "index_events_on_coordinator_id", using: :btree
  add_index "events", ["lat", "lng"], name: "index_events_on_lat_and_lng", using: :btree
  add_index "events", ["ward_id"], name: "index_events_on_ward_id", using: :btree

  create_table "invitations", force: true do |t|
    t.integer  "user_id"
    t.integer  "event_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "send_by"
  end

  add_index "invitations", ["event_id"], name: "index_invitations_on_event_id", using: :btree
  add_index "invitations", ["user_id"], name: "index_invitations_on_user_id", using: :btree

  create_table "roles", force: true do |t|
    t.integer  "user_id"
    t.integer  "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["user_id"], name: "index_roles_on_user_id", using: :btree

  create_table "trees", force: true do |t|
    t.string   "species"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "lat",          precision: 9, scale: 6
    t.decimal  "lng",          precision: 9, scale: 6
    t.integer  "owner_id"
    t.string   "height",                               default: "0"
    t.text     "treatment"
    t.integer  "keep"
    t.text     "additional"
    t.string   "relationship"
    t.string   "subspecies"
    t.date     "ripen"
    t.boolean  "pickable"
    t.integer  "submitter_id"
  end

  add_index "trees", ["owner_id"], name: "index_trees_on_owner_id", using: :btree

  create_table "user_wards", force: true do |t|
    t.integer  "user_id"
    t.integer  "ward_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_wards", ["user_id"], name: "index_user_wards_on_user_id", using: :btree
  add_index "user_wards", ["ward_id"], name: "index_user_wards_on_ward_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                                           default: "",    null: false
    t.string   "encrypted_password",                              default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                                   default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "phone"
    t.text     "address"
    t.decimal  "lat",                     precision: 9, scale: 6
    t.decimal  "lng",                     precision: 9, scale: 6
    t.string   "fname"
    t.string   "lname"
    t.boolean  "snail_mail",                                      default: false
    t.integer  "num_participated_events",                         default: 0
    t.string   "ladder"
    t.text     "contactnotes"
    t.text     "propertynotes"
    t.integer  "ward"
    t.boolean  "waiver",                                          default: false
    t.integer  "home_ward"
    t.string   "do_not_contact_reason"
    t.boolean  "can_email"
    t.boolean  "can_mail"
    t.boolean  "can_phone"
    t.string   "admin_notes"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["lat", "lng"], name: "index_users_on_lat_and_lng", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "wards", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
