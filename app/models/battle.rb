class Battle < ApplicationRecord
  BASE_HP = 3
  POWER_PARTS = { "goggles" => "goggles", "shield" => "shield", "rockets" => "rocket_boots" }.freeze

  belongs_to :learner
  belongs_to :practice_session

  validates :practice_session_id, uniqueness: true
  validates :status, inclusion: { in: %w[active won lost] }
  validates :dino_color, inclusion: { in: %w[green blue peach ice lava cosmic] }
  validates :dino_species, inclusion: { in: %w[rex tricera stego robo] }
  validates :round, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :action_revision, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :next_enemy_move, inclusion: { in: %w[attack guard feint] }, allow_nil: true
  validates :player_max_hp, :enemy_max_hp,
    numericality: { only_integer: true, greater_than_or_equal_to: BASE_HP }
  validates :player_hp, numericality: {
    only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: :player_max_hp
  }
  validates :enemy_hp, numericality: {
    only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: :enemy_max_hp
  }
  validate :completed_mission_belongs_to_learner
  validate :health_matches_status

  def active?
    status == "active"
  end

  def gear_count
    gear_snapshot.length
  end

  def armor_remaining
    [player_hp - BASE_HP, 0].max
  end

  def base_hp
    [player_hp, BASE_HP].min
  end

  def remaining_gear
    gear_snapshot.first(armor_remaining)
  end

  def owns_power?(power)
    key = POWER_PARTS[power]
    key && gear_snapshot.any? { |part| part["key"] == key }
  end

  def power_used?(power)
    power_state.dig(power, "used") == true
  end

  def shield_armed?
    owns_power?("shield") && power_state.dig("shield", "armed") == true
  end

  def road_shield_armed?
    power_state.dig("road_shield", "armed") == true
  end

  private

  def completed_mission_belongs_to_learner
    if practice_session && (practice_session.learner_id != learner_id || !practice_session.completed?)
      errors.add(:practice_session, "мора бити твоја завршена мисија")
    end
  end

  def health_matches_status
    return unless player_hp.is_a?(Integer) && enemy_hp.is_a?(Integer)
    valid = case status
    when "active" then player_hp.positive? && enemy_hp.positive?
    when "won" then player_hp.positive? && enemy_hp.zero?
    when "lost" then player_hp.zero? && enemy_hp.positive?
    else true
    end
    errors.add(:status, "не одговара преосталим животима") unless valid
  end
end
