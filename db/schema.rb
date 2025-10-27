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

ActiveRecord::Schema[8.0].define(version: 2025_10_24_195321) do
  create_table "bill_shares", force: :cascade do |t|
    t.integer "bill_id", null: false
    t.integer "member_id", null: false
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "status", default: "unpaid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_id"], name: "index_bill_shares_on_bill_id"
    t.index ["member_id"], name: "index_bill_shares_on_member_id"
  end

  create_table "bills", force: :cascade do |t|
    t.integer "chore_group_id", null: false
    t.integer "member_id", null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chore_group_id"], name: "index_bills_on_chore_group_id"
    t.index ["member_id"], name: "index_bills_on_member_id"
  end

  create_table "chore_groups", force: :cascade do |t|
    t.string "name"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_chore_groups_on_admin_id"
  end

  create_table "members", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "role"
    t.integer "points"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "chore_group_id", null: false
    t.index ["chore_group_id"], name: "index_members_on_chore_group_id"
    t.index ["user_id"], name: "index_members_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "task_groups", force: :cascade do |t|
    t.integer "chore_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chore_group_id"], name: "index_task_groups_on_chore_group_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.bigint "member_id"
    t.bigint "task_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_tasks_on_member_id"
    t.index ["task_group_id"], name: "index_tasks_on_task_group_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "bill_shares", "bills"
  add_foreign_key "bill_shares", "members"
  add_foreign_key "bills", "chore_groups"
  add_foreign_key "bills", "members"
  add_foreign_key "members", "chore_groups"
  add_foreign_key "members", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "task_groups", "chore_groups"
  add_foreign_key "tasks", "members"
  add_foreign_key "tasks", "task_groups"
end
