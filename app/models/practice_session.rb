class PracticeSession < ApplicationRecord
  belongs_to :learner
  has_many :attempts, dependent: :destroy
  has_one :part_unlock, dependent: :destroy
  has_one :battle, dependent: :destroy
  has_one :road_run, dependent: :destroy

  validates :status, inclusion: { in: %w[active completed] }
  validates :cursor, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :learning_mode, inclusion: { in: %w[school full] }
  validate do
    if school_mode? && !SchoolCurriculum.valid_ids?(school_letter_ids)
      errors.add(:school_letter_ids, "школска мисија мора да сачува изабрана слова")
    end
  end

  def school_mode?
    learning_mode == "school"
  end

  def current_exercise
    exercises[cursor] unless completed?
  end

  def current_exercise_for_display
    exercise = current_exercise
    return exercise unless exercise&.key?("writing_letters")

    # Saved missions keep their original questions and IDs. Only the drawing
    # guides use the current curriculum, including each offered missing letter.
    exercise = exercise.deep_dup
    letter_case = exercise.fetch("case")
    exercise.fetch("writing_letters").each do |letter|
      ([letter] + letter.fetch("options", [])).each do |guide|
        source = Curriculum.find(guide.fetch("letter_id"))
        guide["paths"] = source.fetch("strokes").fetch(letter_case).deep_dup
      end
    end
    exercise
  end

  def completed?
    status == "completed"
  end

  def drive_checkpoint?
    return false if completed? || exercises.empty?

    original_count = exercises.count { |exercise| !exercise["recovery_of"] }
    completed_count = exercises.first(cursor).count { |exercise| !exercise["recovery_of"] }
    original_count >= 2 && completed_count == original_count / 2
  end

  def drive_pending?
    drive_checkpoint? && !road_run&.resolved?
  end

  def total_exercises
    exercises.length
  end

  def progress_percent
    return 0 if total_exercises.zero?
    (100.0 * cursor / total_exercises).round
  end

  def exercise_number
    [cursor + 1, total_exercises].min
  end
end
