class BattleOpponent
  TARGET_VICTORY_CHANCE = 0.75
  TIE_CHANCE = 0.25

  attr_reader :decisive_win_chance

  def initialize(player_hp:, enemy_hp:, random: SecureRandom)
    @random = random
    @decisive_win_chance = calibrated_win_chance(player_hp, enemy_hp)
  end

  def pick(player_move: nil)
    unless BattleArena::MOVES.include?(player_move)
      return BattleArena::MOVES.fetch(@random.random_number(BattleArena::MOVES.length))
    end

    roll = @random.random_number
    return player_move if roll < TIE_CHANCE
    return BattleArena::BEATS.fetch(player_move) if roll < TIE_CHANCE + (1 - TIE_CHANCE) * decisive_win_chance

    BattleArena::BEATS.key(player_move)
  end

  # Ties only delay the result. Sum the chances of landing enemy_hp hits
  # before taking player_hp hits; keep terms in log space for large gear sets.
  def self.victory_chance(player_hp:, enemy_hp:, win_chance:)
    return 0.0 if win_chance.zero?
    return 1.0 if win_chance == 1

    log_term = enemy_hp * Math.log(win_chance)
    log_loss = Math.log(1 - win_chance)
    probability = Math.exp(log_term)
    (1...player_hp).each do |losses|
      log_term += Math.log(enemy_hp + losses - 1) - Math.log(losses) + log_loss
      probability += Math.exp(log_term)
    end
    probability.clamp(0.0, 1.0)
  end

  private

  def calibrated_win_chance(player_hp, enemy_hp)
    # Starting health keeps the odds fixed throughout a fight. Equipment that
    # already beats the target with fair moves must never make the enemy harder.
    chance = ->(value) { self.class.victory_chance(player_hp: player_hp, enemy_hp: enemy_hp, win_chance: value) }
    return 0.5 if chance.call(0.5) >= TARGET_VICTORY_CHANCE

    low, high = 0.5, 1.0
    40.times do
      middle = (low + high) / 2
      chance.call(middle) < TARGET_VICTORY_CHANCE ? low = middle : high = middle
    end
    (low + high) / 2
  end
end
