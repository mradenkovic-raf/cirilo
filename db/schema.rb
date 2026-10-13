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

ActiveRecord::Schema[8.1].define(version: 2026_10_13_000100) do
  create_table "attempts", force: :cascade do |t|
    t.integer "learner_id", null: false
    t.integer "practice_session_id", null: false
    t.string "exercise_id", null: false
    t.string "letter_id", null: false
    t.string "kind", null: false
    t.string "answer"
    t.boolean "correct", default: false, null: false
    t.integer "score"
    t.integer "xp_earned", default: 0, null: false
    t.json "trace_metrics", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["learner_id"], name: "index_attempts_on_learner_id"
    t.index ["practice_session_id", "exercise_id"], name: "one_success_per_exercise", unique: true, where: "correct = 1"
    t.index ["practice_session_id"], name: "index_attempts_on_practice_session_id"
  end

  create_table "battles", force: :cascade do |t|
    t.integer "learner_id", null: false
    t.integer "practice_session_id", null: false
    t.string "status", default: "active", null: false
    t.string "dino_color", default: "green", null: false
    t.json "gear_snapshot", default: [], null: false
    t.integer "player_hp", null: false
    t.integer "player_max_hp", null: false
    t.integer "enemy_hp", null: false
    t.integer "enemy_max_hp", null: false
    t.integer "round", default: 0, null: false
    t.json "turn_history", default: [], null: false
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "dino_species", default: "rex", null: false
    t.json "power_state", default: {}, null: false
    t.string "next_enemy_move"
    t.integer "action_revision", default: 0, null: false
    t.index ["learner_id", "status"], name: "index_battles_on_learner_id_and_status"
    t.index ["learner_id"], name: "index_battles_on_learner_id"
    t.index ["practice_session_id"], name: "index_battles_on_practice_session_id", unique: true
  end

  create_table "learners", force: :cascade do |t|
    t.integer "xp", default: 0, null: false
    t.integer "completed_missions", default: 0, null: false
    t.string "dino_color", default: "green", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "dinosaur_generation", default: 1, null: false
    t.json "last_dino_snapshot", default: {}, null: false
    t.integer "xp_spent", default: 0, null: false
    t.string "selected_dino", default: "rex", null: false
    t.string "selected_theme", default: "meadow", null: false
    t.string "selected_effect", default: "stars", null: false
    t.integer "shop_generation", default: 1, null: false
    t.json "egg_state", default: {}, null: false
    t.string "device_token_digest"
    t.string "learning_mode", default: "school", null: false
    t.json "school_letter_ids", default: ["a", "m", "i", "t", "o", "n", "s", "e"], null: false
    t.integer "learning_settings_revision", default: 0, null: false
    t.index ["device_token_digest"], name: "index_learners_on_device_token_digest", unique: true
    t.check_constraint "xp_spent >= 0 AND xp_spent <= xp", name: "learner_wallet_nonnegative"
  end

  create_table "letter_confusions", force: :cascade do |t|
    t.integer "learner_id", null: false
    t.string "expected_letter_id", null: false
    t.string "chosen_letter_id", null: false
    t.integer "observations", default: 0, null: false
    t.integer "independent_successes", default: 0, null: false
    t.datetime "last_mistake_at", null: false
    t.datetime "last_success_at"
    t.integer "last_success_session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["learner_id", "expected_letter_id", "chosen_letter_id"], name: "unique_observed_letter_pair", unique: true
    t.index ["learner_id"], name: "index_letter_confusions_on_learner_id"
    t.check_constraint "expected_letter_id != chosen_letter_id", name: "different_confused_letters"
    t.check_constraint "observations >= 0 AND independent_successes BETWEEN 0 AND 2", name: "confusion_counts_valid"
  end

  create_table "letter_progresses", force: :cascade do |t|
    t.integer "learner_id", null: false
    t.string "letter_id", null: false
    t.integer "correct_count", default: 0, null: false
    t.integer "incorrect_count", default: 0, null: false
    t.integer "review_level", default: 0, null: false
    t.datetime "last_reviewed_at"
    t.datetime "last_practiced_at"
    t.datetime "next_review_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["learner_id", "letter_id"], name: "index_letter_progresses_on_learner_id_and_letter_id", unique: true
    t.index ["learner_id"], name: "index_letter_progresses_on_learner_id"
  end

  create_table "part_unlocks", force: :cascade do |t|
    t.integer "learner_id", null: false
    t.integer "practice_session_id", null: false
    t.string "part_key", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["learner_id", "part_key"], name: "index_part_unlocks_on_learner_id_and_part_key", unique: true
    t.index ["learner_id"], name: "index_part_unlocks_on_learner_id"
    t.index ["practice_session_id"], name: "index_part_unlocks_on_practice_session_id"
    t.index ["practice_session_id"], name: "one_reward_per_mission", unique: true
  end

  create_table "practice_sessions", force: :cascade do |t|
    t.integer "learner_id", null: false
    t.string "status", default: "active", null: false
    t.json "exercises", default: [], null: false
    t.json "focus_letters", default: [], null: false
    t.integer "cursor", default: 0, null: false
    t.integer "earned_xp", default: 0, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "learning_mode", default: "full", null: false
    t.json "school_letter_ids", default: [], null: false
    t.index ["learner_id"], name: "index_practice_sessions_on_learner_id"
    t.index ["learner_id"], name: "one_active_mission_per_learner", unique: true, where: "status = 'active'"
  end

  create_table "shop_purchases", force: :cascade do |t|
    t.integer "learner_id", null: false
    t.string "item_key", null: false
    t.integer "price_paid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["learner_id", "item_key"], name: "index_shop_purchases_on_learner_id_and_item_key", unique: true
    t.index ["learner_id"], name: "index_shop_purchases_on_learner_id"
    t.check_constraint "price_paid > 0", name: "shop_purchase_positive_price"
  end

  add_foreign_key "attempts", "learners"
  add_foreign_key "attempts", "practice_sessions"
  add_foreign_key "battles", "learners"
  add_foreign_key "battles", "practice_sessions"
  add_foreign_key "letter_confusions", "learners"
  add_foreign_key "letter_progresses", "learners"
  add_foreign_key "part_unlocks", "learners"
  add_foreign_key "part_unlocks", "practice_sessions"
  add_foreign_key "practice_sessions", "learners"
  add_foreign_key "shop_purchases", "learners"
end
