class CreateLetterConfusions < ActiveRecord::Migration[8.1]
  def change
    create_table :letter_confusions do |t|
      t.references :learner, null: false, foreign_key: true
      t.string :expected_letter_id, null: false
      t.string :chosen_letter_id, null: false
      t.integer :observations, null: false, default: 0
      t.integer :independent_successes, null: false, default: 0
      t.datetime :last_mistake_at, null: false
      t.datetime :last_success_at
      # Historical session marker only: resetting cosmetics never deletes evidence.
      t.integer :last_success_session_id
      t.timestamps
      t.index [:learner_id, :expected_letter_id, :chosen_letter_id], unique: true, name: "unique_observed_letter_pair"
      t.check_constraint "expected_letter_id != chosen_letter_id", name: "different_confused_letters"
      t.check_constraint "observations >= 0 AND independent_successes BETWEEN 0 AND 2", name: "confusion_counts_valid"
    end
  end
end
