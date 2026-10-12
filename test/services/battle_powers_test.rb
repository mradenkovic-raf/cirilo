require "test_helper"

class BattlePowersTest < ActiveSupport::TestCase
  setup do
    @learner = Learner.current
    12.times do |index|
      mission = @learner.practice_sessions.create!(status: "completed")
      @learner.part_unlocks.create!(practice_session: mission,
        position: index + 1, part_key: Curriculum.part_at(index + 1).fetch("id"))
    end
    @battle = BattleArena.start!(@learner, @learner.practice_sessions.create!(status: "completed"))
  end

  test "goggles persist exactly one committed move and never reveal the following round" do
    draws = 0
    arena = BattleArena.new(@battle, enemy_picker: -> { draws += 1; "guard" })
    assert_nil BattleArena.state(@battle)[:revealed_enemy_move]
    first = arena.power!(power: "goggles", expected_round: 0, expected_revision: 0)
    assert_equal "guard", first[:revealed_enemy_move]
    assert_equal [0, 1], [first[:round], first[:action_revision]]
    assert first[:powers]["goggles"][:used]
    assert_equal "guard", BattleArena.state(@battle.reload)[:revealed_enemy_move]
    duplicate = arena.power!(power: "goggles", expected_round: 0, expected_revision: 0)
    assert duplicate[:duplicate]
    assert_equal 1, draws

    result = BattleArena.new(Battle.find(@battle.id), enemy_picker: -> { raise "Must use committed move" })
      .move!(move: "feint", expected_round: 0, expected_revision: 1)
    assert_equal "guard", result[:enemy_move]
    assert_equal "win", result[:outcome]
    assert_nil result[:revealed_enemy_move]
    assert_nil @battle.reload.next_enemy_move
    assert_equal [1, 2], [@battle.round, @battle.action_revision]
    assert arena.power!(power: "goggles", expected_round: 0, expected_revision: 0)[:duplicate]
    assert_raises(BattleArena::StaleMove) { arena.power!(power: "goggles", expected_round: 1, expected_revision: 2) }
    assert_equal 0, @learner.reload.xp
  end

  test "shield waits through ties and wins and cancels exactly the next hit without dropping gear" do
    arena = BattleArena.new(@battle, enemy_picker: -> { "attack" })
    initial_hp = @battle.player_hp
    armed = arena.power!(power: "shield", expected_round: 0, expected_revision: 0)
    assert armed[:shield_armed]
    assert_nil armed[:revealed_enemy_move]
    assert_equal 0, armed[:round]
    assert_equal "tie", arena.move!(move: "attack", expected_round: 0)[:outcome]
    assert_equal "win", arena.move!(move: "guard", expected_round: 1)[:outcome]
    assert @battle.reload.shield_armed?
    blocked = arena.move!(move: "feint", expected_round: 2)
    assert_equal "blocked", blocked[:outcome]
    assert_equal initial_hp, blocked[:player_hp]
    assert_nil blocked[:dropped_part]
    assert_not blocked[:shield_armed]
    assert blocked[:powers]["shield"][:used]
    hit = arena.move!(move: "feint", expected_round: 3)
    assert_equal "lose", hit[:outcome]
    assert_equal initial_hp - 1, hit[:player_hp]
    assert_equal "rocket_boots", hit[:dropped_part]["key"]
    assert_equal 12, @learner.part_unlocks.count
  end

  test "easier opponent never changes a revealed move to manufacture a win" do
    draws = []
    random = Object.new
    random.define_singleton_method(:random_number) do |limit = nil|
      draws << limit
      raise "Revealed move must not be redrawn" unless draws.length == 1 && limit == 3
      2 # feint, committed before the child chooses
    end
    revealed = BattleArena.new(@battle, random: random)
      .power!(power: "goggles", expected_round: 0, expected_revision: 0)
    assert_equal "feint", revealed[:revealed_enemy_move]
    result = BattleArena.new(Battle.find(@battle.id), random: random)
      .move!(move: "guard", expected_round: 0, expected_revision: 1)
    assert_equal "feint", result[:enemy_move]
    assert_equal "lose", result[:outcome]
    assert_equal [3], draws
    assert_equal @battle.player_max_hp - 1, result[:player_hp]
  end

  test "rockets consume one whole neutral round and leave an armed shield ready" do
    arena = BattleArena.new(@battle, enemy_picker: -> { "feint" })
    arena.power!(power: "shield", expected_round: 0, expected_revision: 0)
    before = @battle.values_at(:player_hp, :enemy_hp)
    result = arena.power!(power: "rockets", expected_round: 0, expected_revision: 1)
    assert_equal "dodge", result[:outcome]
    assert_equal "dodge", result[:player_move]
    assert_equal "feint", result[:enemy_move]
    assert_equal before, @battle.reload.values_at(:player_hp, :enemy_hp)
    assert_equal [1, 2], @battle.values_at(:round, :action_revision)
    assert result[:shield_armed]
    assert_nil result[:dropped_part]
    assert result[:powers]["rockets"][:used]
    assert arena.power!(power: "rockets", expected_round: 0, expected_revision: 1)[:duplicate]
    assert_equal 1, @battle.reload.turn_history.length
    assert_raises(BattleArena::StaleMove) { arena.move!(move: "attack", expected_round: 0, expected_revision: 1) }
    assert_equal 0, @learner.reload.xp
  end

  test "powers belong to the original earned gear snapshot and survive gear loss or workshop reset" do
    @battle.update!(player_hp: Battle::BASE_HP)
    assert_equal [], @battle.remaining_gear
    DinoReset.reset!(@learner, confirmation: "1", generation: @learner.dinosaur_generation)
    result = BattleArena.new(@battle).power!(power: "rockets", expected_round: 0, expected_revision: 0)
    assert_equal "dodge", result[:outcome]
    assert_equal 3, result[:player_hp]
    assert_equal 0, @learner.part_unlocks.count

    newer = BattleArena.start!(@learner, @learner.practice_sessions.create!(status: "completed"))
    assert BattleArena.state(newer)[:powers].values.none? { |power| power[:owned] }
    assert_raises(BattleArena::InvalidMove) do
      BattleArena.new(newer).power!(power: "rockets", expected_round: 0, expected_revision: 0)
    end
  end

  test "historical active battles with empty power state can use their saved gear" do
    @battle.update!(round: 1, turn_history: [{ "round" => 1, "player_move" => "attack", "enemy_move" => "attack", "outcome" => "tie" }])
    assert_equal({}, @battle.power_state)
    result = BattleArena.new(@battle, enemy_picker: -> { "feint" }).power!(power: "goggles", expected_round: 1, expected_revision: 0)
    assert_equal "feint", result[:revealed_enemy_move]
    assert_equal 1, result[:round]
  end

  test "newer power state rejects stale moves while old rendered pages remain compatible" do
    arena = BattleArena.new(@battle, enemy_picker: -> { "attack" })
    arena.power!(power: "goggles", expected_round: 0, expected_revision: 0)
    assert_raises(BattleArena::StaleMove) { arena.move!(move: "guard", expected_round: 0, expected_revision: 0) }
    assert_equal 0, @battle.reload.round
    assert_equal "win", arena.move!(move: "guard", expected_round: 0)[:outcome]
  end

  test "malformed missing and unavailable powers cannot change any saved state" do
    arena = BattleArena.new(@battle)
    original = @battle.attributes
    [nil, "", "jetpack", ["goggles"], { "power" => "shield" }].each do |power|
      assert_raises(BattleArena::InvalidMove) { arena.power!(power: power, expected_round: 0, expected_revision: 0) }
    end
    [nil, "", -1, "00", "0x", 0.2, [0], {}].each do |revision|
      assert_raises(BattleArena::InvalidMove) { arena.power!(power: "shield", expected_round: 0, expected_revision: revision) }
    end
    assert_raises(BattleArena::StaleMove) { arena.power!(power: "shield", expected_round: 9, expected_revision: 0) }
    assert_equal original, @battle.reload.attributes
  end

  test "a finished battle does not accept unused powers or leak the next move" do
    @battle.update!(status: "won", enemy_hp: 0, finished_at: Time.current)
    assert BattleArena.state(@battle)[:powers].values.none? { |power| power[:available] }
    assert_raises(BattleArena::StaleMove) do
      BattleArena.new(@battle).power!(power: "shield", expected_round: 0, expected_revision: 0)
    end
    assert_nil BattleArena.state(@battle)[:revealed_enemy_move]
  end
end
