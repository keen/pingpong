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

ActiveRecord::Schema.define(version: 20150122183444) do

  create_table "checks", force: true do |t|
    t.string   "name"
    t.string   "url"
    t.integer  "frequency"
    t.string   "method"
    t.text     "data"
    t.text     "save_body"
    t.string   "http_username"
    t.string   "http_password"
    t.text     "custom_properties"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "checks", ["name"], name: "index_checks_on_name", unique: true

end
