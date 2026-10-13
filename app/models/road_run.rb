class RoadRun < ApplicationRecord
  belongs_to :practice_session

  validates :practice_session_id, uniqueness: true
  validates :status, inclusion: { in: %w[active won lost skipped] }
  validates :token, presence: true
  validates :hits, numericality: { only_integer: true, in: 0..3 }
  validates :elapsed_ms, numericality: { only_integer: true, in: 0..24_000 }

  def resolved?
    status != "active"
  end

  def shield_earned?
    status == "won"
  end
end
