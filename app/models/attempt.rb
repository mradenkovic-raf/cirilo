class Attempt < ApplicationRecord
  belongs_to :learner
  belongs_to :practice_session
  validates :exercise_id, :letter_id, presence: true
  validates :kind, inclusion: { in: %w[recognize case_match trace word build_word read_word sentence memory_word write_word fill_letters story_action picture_word repair_word word_pairs] }
  validates :score, numericality: { only_integer: true, in: 0..100 }, allow_nil: true
end
