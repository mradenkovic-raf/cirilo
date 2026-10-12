raise "Test environment only" unless Rails.env.test?

samples = 20_000
results = [0, 1, 4, 8, 16].map do |gear|
  starting_player = 3 + gear
  starting_enemy = 3 + (gear * 0.75).ceil
  opponent = BattleOpponent.new(player_hp: starting_player, enemy_hp: starting_enemy,
    random: Random.new(1300 + gear))
  wins = 0
  samples.times do
    player_hp = starting_player
    enemy_hp = starting_enemy
    turn = 0
    until player_hp.zero? || enemy_hp.zero?
      move = BattleArena::MOVES.fetch(turn % 3)
      enemy = opponent.pick(player_move: move)
      if BattleArena::BEATS.fetch(move) == enemy
        enemy_hp -= 1
      elsif enemy != move
        player_hp -= 1
      end
      turn += 1
    end
    wins += 1 if enemy_hp.zero?
  end
  { gear: gear, fights: samples, wins: wins, victory_percent: (100.0 * wins / samples).round(2),
    calculated_percent: (100 * BattleOpponent.victory_chance(player_hp: starting_player,
      enemy_hp: starting_enemy, win_chance: opponent.decisive_win_chance)).round(3) }
end
puts JSON.pretty_generate(results)
