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

ActiveRecord::Schema.define(version: 20150427160230) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "checks", force: :cascade do |t|
    t.string   "name"
    t.string   "url"
    t.integer  "frequency"
    t.string   "method"
    t.text     "headers"
    t.text     "data"
    t.boolean  "save_body"
    t.string   "http_username"
    t.string   "http_password"
    t.text     "custom_properties"
    t.text     "incident_checking"
    t.text     "configurations",    default: "{\"email_warn\":false, \"email_bad\":true}"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "checks", ["name"], name: "index_checks_on_name", unique: true, using: :btree

  create_table "incidents", force: :cascade do |t|
    t.integer  "check_id"
    t.integer  "incident_type"
    t.text     "info"
    t.text     "check_response"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "incidents", ["check_id"], name: "index_incidents_on_check_id", using: :btree

end
