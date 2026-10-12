class LetterConfusion < ApplicationRecord
  belongs_to :learner
  validates :expected_letter_id, :chosen_letter_id, inclusion: { in: ->(_) { Curriculum.letters.map { |letter| letter.fetch("id") } } }
  validates :expected_letter_id, uniqueness: { scope: [:learner_id, :chosen_letter_id] }
  validates :observations, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :independent_successes, numericality: { only_integer: true, in: 0..2 }
  validates :last_mistake_at, presence: true
  validate { errors.add(:chosen_letter_id, "must differ") if expected_letter_id == chosen_letter_id }

  scope :for_learner, ->(learner) { where(learner_id: learner.id) }
  scope :active, -> { where(independent_successes: 0..1) }
  scope :prioritized, -> { order(Arel.sql("CASE WHEN independent_successes < 2 THEN 0 ELSE 1 END"), observations: :desc, last_mistake_at: :desc, id: :asc) }

  def expected_letter = Curriculum.find(expected_letter_id)
  def chosen_letter = Curriculum.find(chosen_letter_id)
end
