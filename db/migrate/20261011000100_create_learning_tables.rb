class CreateLearningTables < ActiveRecord::Migration[8.1]
  def change
    create_table :learners do |t|
      t.string :singleton_key, null: false, default: "child"
      t.integer :xp, null: false, default: 0
      t.integer :completed_missions, null: false, default: 0
      t.string :dino_color, null: false, default: "green"
      t.timestamps
    end
    add_index :learners, :singleton_key, unique: true

    create_table :letter_progresses do |t|
      t.references :learner, null: false, foreign_key: true
      t.string :letter_id, null: false
      t.integer :correct_count, null: false, default: 0
      t.integer :incorrect_count, null: false, default: 0
      t.integer :review_level, null: false, default: 0
      t.datetime :last_reviewed_at
      t.datetime :last_practiced_at
      t.datetime :next_review_at
      t.timestamps
    end
    add_index :letter_progresses, [:learner_id, :letter_id], unique: true

    create_table :practice_sessions do |t|
      t.references :learner, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.json :exercises, null: false, default: []
      t.json :focus_letters, null: false, default: []
      t.integer :cursor, null: false, default: 0
      t.integer :earned_xp, null: false, default: 0
      t.datetime :completed_at
      t.timestamps
    end
    add_index :practice_sessions, :learner_id, unique: true, where: "status = 'active'", name: "one_active_mission_per_learner"

    create_table :attempts do |t|
      t.references :learner, null: false, foreign_key: true
      t.references :practice_session, null: false, foreign_key: true
      t.string :exercise_id, null: false
      t.string :letter_id, null: false
      t.string :kind, null: false
      t.string :answer
      t.boolean :correct, null: false, default: false
      t.integer :score
      t.integer :xp_earned, null: false, default: 0
      t.json :trace_metrics, null: false, default: {}
      t.timestamps
    end
    add_index :attempts, [:practice_session_id, :exercise_id], unique: true,
      where: "correct = 1", name: "one_success_per_exercise"

    create_table :part_unlocks do |t|
      t.references :learner, null: false, foreign_key: true
      t.references :practice_session, null: false, foreign_key: true
      t.string :part_key, null: false
      t.integer :position, null: false
      t.timestamps
    end
    add_index :part_unlocks, [:learner_id, :part_key], unique: true
    add_index :part_unlocks, :practice_session_id, unique: true, name: "one_reward_per_mission"
  end
end
