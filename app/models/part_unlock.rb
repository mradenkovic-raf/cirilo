class PartUnlock < ApplicationRecord
  belongs_to :learner
  belongs_to :practice_session
  validates :part_key, presence: true, uniqueness: { scope: :learner_id }
  validates :practice_session_id, uniqueness: true

  def part
    Curriculum.part_at(position)
  end
end
