require "test_helper"

class BattleOpponentTest < ActiveSupport::TestCase
  test "ordinary fights target seventy five percent without weakening stronger gear" do
    [ *(0..17), 40, 128, 1000 ].each do |gear|
      player_hp = 3 + gear
      enemy_hp = 3 + (gear * 0.75).ceil
      opponent = BattleOpponent.new(player_hp: player_hp, enemy_hp: enemy_hp)
      fair_chance = independent_victory_chance(player_hp, enemy_hp, 0.5)
      actual_chance = independent_victory_chance(player_hp, enemy_hp, opponent.decisive_win_chance)

      assert_in_delta [0.75, fair_chance].max, actual_chance, 1e-9, "gear #{gear}"
      assert_operator opponent.decisive_win_chance, :>=, 0.5
      assert_operator opponent.decisive_win_chance, :<, 1
      assert_equal 0.5, opponent.decisive_win_chance if fair_chance >= 0.75
    end
  end

  test "every move can tie win or lose including exact probability boundaries" do
    random = StubRandom.new
    opponent = BattleOpponent.new(player_hp: 3, enemy_hp: 3, random: random)
    win_limit = 0.25 + 0.75 * opponent.decisive_win_chance

    BattleArena::MOVES.each do |move|
      [ [0.0, move], [0.25.prev_float, move],
        [0.25, BattleArena::BEATS.fetch(move)], [win_limit.prev_float, BattleArena::BEATS.fetch(move)],
        [win_limit, BattleArena::BEATS.key(move)], [1.0.prev_float, BattleArena::BEATS.key(move)] ].each do |roll, enemy|
        random.value = roll
        assert_equal enemy, opponent.pick(player_move: move), "#{move}, roll #{roll}"
        assert_nil random.last_limit
      end
    end
  end

  test "an unknown player choice is uniformly selected for goggles and dodging" do
    random = StubRandom.new
    opponent = BattleOpponent.new(player_hp: 3, enemy_hp: 3, random: random)

    [nil, "dodge", "unknown"].each do |move|
      BattleArena::MOVES.each_with_index do |enemy, index|
        random.value = index
        assert_equal enemy, opponent.pick(player_move: move)
        assert_equal 3, random.last_limit
      end
    end
  end

  test "victory calculation covers certain outcomes and does not underflow with many hearts" do
    assert_equal 0.0, BattleOpponent.victory_chance(player_hp: 3, enemy_hp: 3, win_chance: 0.0)
    assert_equal 1.0, BattleOpponent.victory_chance(player_hp: 3, enemy_hp: 3, win_chance: 1.0)
    assert_in_delta 0.7491026944, BattleOpponent.victory_chance(player_hp: 3, enemy_hp: 3, win_chance: 0.64), 1e-12
    assert_in_delta 0.5, BattleOpponent.victory_chance(player_hp: 1500, enemy_hp: 1500, win_chance: 0.5), 1e-9
  end

  private

  # Independent absorbing-state calculation, using two small rows rather
  # than the production negative-binomial formula.
  def independent_victory_chance(player_hp, enemy_hp, win_chance)
    previous = Array.new(enemy_hp + 1, 0.0)
    previous[0] = 1.0
    player_hp.times do
      current = Array.new(enemy_hp + 1, 1.0)
      (1..enemy_hp).each do |enemy|
        current[enemy] = win_chance * current[enemy - 1] + (1 - win_chance) * previous[enemy]
      end
      previous = current
    end
    previous.last
  end

  class StubRandom
    attr_accessor :value
    attr_reader :last_limit

    def random_number(limit = nil)
      @last_limit = limit
      value
    end
  end
end
