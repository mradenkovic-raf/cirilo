class AddSchoolLearningSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :learners, :learning_mode, :string, default: "school", null: false
    add_column :learners, :school_letter_ids, :json, default: %w[a m i t o n s e], null: false
    add_column :learners, :learning_settings_revision, :integer, default: 0, null: false

    # Existing missions retain their questions and full-alphabet scope. A new
    # mission stores its own settings so a parent's later edit cannot change it.
    add_column :practice_sessions, :learning_mode, :string, default: "full", null: false
    add_column :practice_sessions, :school_letter_ids, :json, default: [], null: false
  end
end
