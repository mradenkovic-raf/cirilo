require "test_helper"

class BattleArenaTest < ActiveSupport::TestCase
  setup do
    @learner = Learner.current
    @learner.update!(xp: 500, completed_missions: 4, dino_color: "blue")
    4.times { |index| add_reward(index + 1) }
    @session = completed_session
  end

  test "one persistent battle snapshots equipment and scales both health bars" do
    battle = BattleArena.start!(@learner, @session)
    assert_equal battle.id, BattleArena.start!(@learner, @session).id
    assert_equal 1, @learner.battles.count
    assert_equal 7, battle.player_max_hp
    assert_equal 6, battle.enemy_max_hp
    assert_equal 3, battle.base_hp
    assert_equal 4, battle.armor_remaining
    assert_equal "blue", battle.dino_color
    assert_equal @learner.part_unlocks.order(:position).pluck(:part_key), battle.gear_snapshot.map { |part| part["key"] }
    assert_equal %w[emoji key name position], battle.gear_snapshot.first.keys.sort
    assert_equal 0, battle.round
  end

  test "health includes all sixteen parts and later crystals" do
    (5..17).each { |position| add_reward(position) }
    battle = BattleArena.start!(@learner, @session)
    assert_equal 17, battle.gear_count
    assert_equal 20, battle.player_hp
    assert_equal 16, battle.enemy_hp
    assert_equal 17, BattleArena.state(battle).fetch(:remaining_gear).size
  end

  test "all nine move combinations follow attack guard feint rules" do
    winners = { "attack" => "feint", "guard" => "attack", "feint" => "guard" }
    BattleArena::MOVES.product(BattleArena::MOVES).each do |player, enemy|
      battle = BattleArena.start!(@learner, completed_session)
      result = BattleArena.new(battle, enemy_picker: -> { enemy }).move!(move: player, expected_round: 0)
      expected = player == enemy ? "tie" : winners.fetch(player) == enemy ? "win" : "lose"
      assert_equal expected, result[:outcome], "#{player} vs #{enemy}"
      assert_equal 7 - (expected == "lose" ? 1 : 0), result[:player_hp]
      assert_equal 6 - (expected == "win" ? 1 : 0), result[:enemy_hp]
      assert_equal player, result[:player_move]
      assert_equal enemy, result[:enemy_move]
      assert_equal 1, battle.reload.turn_history.size
      assert_equal result.except(:success, :duplicate), BattleArena.state(Battle.find(battle.id))
    end
  end

  test "hits remove snapshot gear one at a time before the three base hearts" do
    battle = BattleArena.start!(@learner, @session)
    arena = BattleArena.new(battle, enemy_picker: -> { "guard" })
    4.downto(1) do |position|
      result = arena.move!(move: "attack", expected_round: battle.round)
      assert_equal position, result.fetch(:dropped_part).fetch("position")
      assert_equal position - 1, result[:armor_remaining]
      assert_equal 3, result[:base_hp]
    end
    2.downto(0) do |hearts|
      result = arena.move!(move: "attack", expected_round: battle.round)
      assert_nil result[:dropped_part]
      assert_equal hearts, result[:base_hp]
    end
    assert_equal "lost", battle.reload.status
    assert_not_nil battle.finished_at
    assert_equal 4, @learner.part_unlocks.count
    assert_equal [500, 4], @learner.reload.values_at(:xp, :completed_missions)
    assert_nil BattleArena.state(battle)[:medal]
  end

  test "normal opponent can favor every child move and replay never draws a new result" do
    BattleArena::MOVES.each do |move|
      draws = 0
      random = Object.new
      random.define_singleton_method(:random_number) { draws += 1; 0.5 }
      battle = BattleArena.start!(@learner, completed_session)
      result = BattleArena.new(battle, random: random).move!(move: move, expected_round: 0)
      assert_equal "win", result[:outcome]
      assert_equal BattleArena::BEATS.fetch(move), result[:enemy_move]
      assert_equal 7, result[:player_hp]
      assert_equal 5, result[:enemy_hp]

      replay = BattleArena.new(Battle.find(battle.id), random: random).move!(move: move, expected_round: 0)
      assert replay[:duplicate]
      assert_equal 1, draws
      assert_equal result.except(:duplicate), replay.except(:duplicate)
    end
    assert_equal [500, 4], @learner.reload.values_at(:xp, :completed_missions)
  end

  test "a victory records one medal without XP or reward farming or replaying a finished battle" do
    battle = BattleArena.start!(@learner, @session)
    arena = BattleArena.new(battle, enemy_picker: -> { "feint" })
    battle.enemy_max_hp.times { arena.move!(move: "attack", expected_round: battle.round) }
    assert_equal "won", battle.reload.status
    assert_equal "victory", BattleArena.state(battle)[:medal]
    assert_equal 1, @learner.battles.where(status: "won").count
    assert_equal battle.id, BattleArena.start!(@learner, @session).id
    assert_raises(BattleArena::StaleMove) { arena.move!(move: "attack", expected_round: battle.round) }
    replay = arena.move!(move: "attack", expected_round: battle.round - 1)
    assert replay[:duplicate]
    assert_equal "victory", replay[:medal]
    assert_equal [500, 4], @learner.reload.values_at(:xp, :completed_missions)
    assert_equal 4, @learner.part_unlocks.count
  end

  test "same round and move replay is idempotent and conflicting or future rounds are stale" do
    battle = BattleArena.start!(@learner, @session)
    draws = 0
    arena = BattleArena.new(battle, enemy_picker: -> { draws += 1; "feint" })
    first = arena.move!(move: "attack", expected_round: "0")
    replay = arena.move!(move: "attack", expected_round: 0)
    assert replay[:duplicate]
    assert_equal first.except(:duplicate), replay.except(:duplicate)
    assert_equal 1, draws
    assert_raises(BattleArena::StaleMove) { arena.move!(move: "guard", expected_round: 0) }
    assert_raises(BattleArena::StaleMove) { arena.move!(move: "guard", expected_round: 2) }
    assert_equal 1, battle.reload.round
    assert_equal 1, draws
  end

  test "malformed moves and round values never change a battle" do
    battle = BattleArena.start!(@learner, @session)
    arena = BattleArena.new(battle)
    [nil, "", "win", "ATTACK", ["attack"], { "move" => "attack" }].each do |move|
      assert_raises(BattleArena::InvalidMove) { arena.move!(move: move, expected_round: 0) }
    end
    [nil, "", "00", "0x", -1, 0.1, [0], { "round" => 0 }].each do |round|
      assert_raises(BattleArena::InvalidMove) { arena.move!(move: "attack", expected_round: round) }
    end
    assert_equal 0, battle.reload.round
    assert_equal [], battle.turn_history
  end

  test "starting requires a completed mission owned by the learner" do
    active = @learner.practice_sessions.create!
    assert_raises(BattleArena::InvalidBattle) { BattleArena.start!(@learner, active) }
    other = Learner.new(singleton_key: "test-other")
    other.save!(validate: false)
    foreign = other.practice_sessions.create!(status: "completed")
    assert_raises(ActiveRecord::RecordNotFound) { BattleArena.start!(@learner, foreign) }
    assert_equal 0, @learner.battles.count
  end

  test "an existing battle keeps its equipment and color after a workshop reset" do
    battle = BattleArena.start!(@learner, @session)
    snapshot = battle.gear_snapshot.deep_dup
    DinoReset.reset!(@learner, confirmation: "1", generation: @learner.dinosaur_generation)
    @learner.update!(dino_color: "peach")
    result = BattleArena.new(battle, enemy_picker: -> { "guard" }).move!(move: "attack", expected_round: 0)
    assert_equal snapshot, battle.reload.gear_snapshot
    assert_equal "blue", result[:dino_color]
    assert_equal 3, result[:armor_remaining]
    assert_equal 0, @learner.part_unlocks.count
    assert_equal battle.id, BattleArena.start!(@learner, @session).id
  end

  private

  def completed_session
    @learner.practice_sessions.create!(status: "completed", completed_at: Time.current)
  end

  def add_reward(position)
    @learner.part_unlocks.create!(practice_session: completed_session,
      part_key: Curriculum.part_at(position).fetch("id"), position: position)
  end
end
