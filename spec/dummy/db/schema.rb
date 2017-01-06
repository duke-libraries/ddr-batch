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

ActiveRecord::Schema.define(version: 20161116142512) do

  create_table "batch_object_attributes", force: :cascade do |t|
    t.integer  "batch_object_id"
    t.string   "datastream",      limit: 255
    t.string   "name",            limit: 255
    t.string   "operation",       limit: 255
    t.text     "value",           limit: 65535
    t.string   "value_type",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "batch_object_datastreams", force: :cascade do |t|
    t.integer  "batch_object_id"
    t.string   "operation",       limit: 255
    t.string   "name",            limit: 255
    t.text     "payload"
    t.string   "payload_type",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "checksum",        limit: 255
    t.string   "checksum_type",   limit: 255
  end

  create_table "batch_object_messages", force: :cascade do |t|
    t.integer  "batch_object_id"
    t.integer  "level",                         default: 0
    t.text     "message",         limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "batch_object_relationships", force: :cascade do |t|
    t.integer  "batch_object_id"
    t.string   "name",            limit: 255
    t.string   "operation",       limit: 255
    t.string   "object",          limit: 255
    t.string   "object_type",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "batch_object_roles", force: :cascade do |t|
    t.integer  "batch_object_id"
    t.string   "operation",       limit: 255
    t.string   "agent",           limit: 255
    t.string   "role_type",       limit: 255
    t.string   "role_scope",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "batch_objects", force: :cascade do |t|
    t.integer  "batch_id"
    t.string   "identifier", limit: 255
    t.string   "model",      limit: 255
    t.string   "label",      limit: 255
    t.string   "pid",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",       limit: 255
    t.boolean  "verified",               default: false
    t.boolean  "handled",                default: false
    t.boolean  "processed",              default: false
    t.boolean  "validated",              default: false
  end

  add_index "batch_objects", ["verified"], name: "index_batch_objects_on_verified"

  create_table "batches", force: :cascade do |t|
    t.string   "name",                  limit: 255
    t.string   "description",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "status",                limit: 255
    t.datetime "start"
    t.datetime "stop"
    t.string   "outcome",               limit: 255
    t.integer  "failure",                           default: 0
    t.integer  "success",                           default: 0
    t.string   "version",               limit: 255
    t.string   "logfile_file_name",     limit: 255
    t.string   "logfile_content_type",  limit: 255
    t.integer  "logfile_file_size"
    t.datetime "logfile_updated_at"
    t.datetime "processing_step_start"
  end

  create_table "bookmarks", force: :cascade do |t|
    t.integer  "user_id",                   null: false
    t.string   "user_type",     limit: 255
    t.string   "document_id",   limit: 255
    t.string   "title",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "document_type", limit: 255
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id"

  create_table "events", force: :cascade do |t|
    t.datetime "event_date_time"
    t.integer  "user_id"
    t.string   "type",            limit: 255
    t.string   "pid",             limit: 255
    t.string   "software",        limit: 255
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "summary",         limit: 255
    t.string   "outcome",         limit: 255
    t.text     "detail"
    t.text     "exception",       limit: 65535
    t.string   "user_key",        limit: 255
    t.string   "permanent_id",    limit: 255
  end

  add_index "events", ["event_date_time"], name: "index_events_on_event_date_time"
  add_index "events", ["outcome"], name: "index_events_on_outcome"
  add_index "events", ["permanent_id"], name: "index_events_on_permanent_id"
  add_index "events", ["pid"], name: "index_events_on_pid"
  add_index "events", ["type"], name: "index_events_on_type"

  create_table "searches", force: :cascade do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.string   "user_type",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id"

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "username",               limit: 255, default: "", null: false
    t.string   "first_name",             limit: 255
    t.string   "middle_name",            limit: 255
    t.string   "nickname",               limit: 255
    t.string   "last_name",              limit: 255
    t.string   "display_name",           limit: 255
  end

  add_index "users", ["email"], name: "index_users_on_email"
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  add_index "users", ["username"], name: "index_users_on_username", unique: true

end
