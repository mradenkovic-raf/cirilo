require "test_helper"
require_relative "exercise_helpers"

class DinoDriveTest < ActiveSupport::TestCase
  include ExerciseHelpers

  setup do
    @learner = Learner.create!
    @mission = PracticePlanner.start!(@learner)
    @drive = DinoDrive.new(@mission)
  end

  test "both modes offer one drive after six original tasks with no XP or cursor change" do
    %w[school full].each do |mode|
      learner = Learner.create!(learning_mode: mode)
      mission = PracticePlanner.start!(learner)
      assert_not mission.drive_pending?
      assert_raises(DinoDrive::InvalidRun) { DinoDrive.new(mission).start! }
      6.times { solve_current_exercise(mission) }
      assert mission.reload.drive_pending?
      before = [mission.cursor, learner.reload.xp]
      run = DinoDrive.new(mission).start!
      assert_equal run.id, DinoDrive.new(PracticeSession.find(mission.id)).start!.id
      assert_equal 11, run.obstacles.length
      assert run.obstacles.each_cons(2).all? { |a, b| b["at_ms"] - a["at_ms"] >= 1800 }
      assert run.obstacles.group_by { |rock| rock["lane"] }.values.all? { |rocks| rocks.size >= 3 }
      assert_equal before, [mission.reload.cursor, learner.reload.xp]
    end
  end

  test "inserted recovery tasks do not move the halfway point" do
    originals = @mission.exercises.deep_dup
    recovery = originals.first.merge("recovery_of" => originals.first.fetch("id"), "id" => SecureRandom.uuid)
    @mission.update!(exercises: [recovery] + originals, cursor: 6)
    assert_not @mission.drive_pending?
    @mission.update!(cursor: 7)
    assert @mission.drive_pending?
  end

  test "winning records one shield and duplicate or skip requests cannot alter it" do
    run = start_drive
    assert_raises(DinoDrive::InvalidRun) { finish(run, winning_moves(run), 24_000) }
    travel 25.seconds do
      result = finish(run, winning_moves(run), 24_000)
      assert_equal "won", result.status
      assert result.shield_earned?
      assert_equal 0, result.hits
      assert_equal result.attributes, finish(run, [], 0).attributes
      assert_equal result.attributes, @drive.skip!.attributes
      assert_equal result.id, @drive.start!.id
    end
    assert_not @mission.reload.drive_pending?
    assert_equal [6, 0], [@mission.cursor, @learner.reload.xp]
    @mission.update!(status: "completed", cursor: @mission.exercises.size, completed_at: Time.current)
    battle = BattleArena.start!(@learner, @mission)
    assert battle.road_shield_armed?
    assert_equal [3, 3], [battle.player_hp, battle.enemy_hp]
    assert_equal battle.id, BattleArena.start!(@learner, @mission).id
  end

  test "three actual collisions end the drive without changing learning progress" do
    run = start_drive
    result = DinoDrive.evaluate(run.obstacles, [], 24_000)
    travel 25.seconds do
      finish(run, [], result.fetch(:elapsed_ms))
    end
    assert_equal ["lost", 3, false], [run.reload.status, run.hits, run.shield_earned?]
    assert_not @mission.reload.drive_pending?
    assert_equal [6, 0, 0], [@mission.cursor, @learner.reload.xp, @learner.completed_missions]
  end

  test "short incomplete runs wrong tokens and invalid lane histories cannot award a shield" do
    run = start_drive
    travel 25.seconds do
      assert_raises(DinoDrive::InvalidRun) { @drive.finish!(token: "wrong", moves: [], elapsed_ms: 24_000) }
      assert_raises(DinoDrive::InvalidRun) { finish(run, [], 1000) }
      [nil, {}, [nil], [{ "at_ms" => 0, "lane" => 3 }], [{ "at_ms" => -1, "lane" => 0 }],
        [{ "at_ms" => 0, "lane" => 0 }, { "at_ms" => 100, "lane" => 1 }],
        [{ "at_ms" => 0, "lane" => 0 }, { "at_ms" => 500, "lane" => 2 }],
        [{ "at_ms" => 25_000, "lane" => 0 }], [{ "at_ms" => 0.1, "lane" => 0 }],
        [{ "at_ms" => 0, "lane" => 0, "won" => true }]].each do |moves|
        assert_raises(DinoDrive::InvalidRun) { finish(run, moves, 24_000) }
      end
      [nil, "24000", 24_000.5, -1, 24_001].each do |elapsed|
        assert_raises(DinoDrive::InvalidRun) { finish(run, [], elapsed) }
      end
    end
    assert_equal "active", run.reload.status
  end

  test "same timestamp moves are evaluated before rocks and third hit stops the course" do
    obstacles = [1000, 2000, 3000, 4000].map { |time| { "at_ms" => time, "lane" => 1 } }
    assert_equal({ hits: 0, elapsed_ms: 24_000 }, DinoDrive.evaluate(obstacles, [{ "at_ms" => 1000, "lane" => 0 }], 24_000))
    assert_equal({ hits: 3, elapsed_ms: 3000 }, DinoDrive.evaluate(obstacles, [], 24_000))
  end

  test "skip works without starting and cannot be farmed by restarting or reloading" do
    @mission.update!(cursor: 6)
    run = @drive.skip!
    assert_equal "skipped", run.status
    assert_equal run.id, @drive.start!.id
    assert_equal run.id, @drive.skip!.id
    assert_not run.shield_earned?
    assert_not @mission.reload.drive_pending?
    assert_equal 1, RoadRun.count
  end

  test "a stale open drive cannot add rewards after the learner has passed the checkpoint" do
    run = start_drive
    @mission.update!(cursor: 7)
    travel 25.seconds do
      assert_raises(DinoDrive::InvalidRun) { finish(run, winning_moves(run), 24_000) }
    end
    assert_not run.reload.shield_earned?
  end

  test "road shield blocks once before equipment shield and does not strengthen the opponent" do
    mission = @learner.practice_sessions.create!(status: "completed")
    mission.create_road_run!(token: "fixture", status: "won", elapsed_ms: 24_000)
    battle = BattleArena.start!(@learner, mission)
    # A purchased shield can already be armed, independently of the race bonus.
    battle.update!(gear_snapshot: [{ "position" => 1, "key" => "shield", "name" => "Штит", "emoji" => "🛡️" }],
      player_hp: 4, player_max_hp: 4,
      power_state: battle.power_state.merge("shield" => { "used" => true, "armed" => true }))
    arena = BattleArena.new(battle, enemy_picker: -> { "guard" })
    first = arena.move!(move: "attack", expected_round: 0)
    assert_equal ["blocked", "road_shield", 4, true, false],
      first.values_at(:outcome, :blocked_by, :player_hp, :shield_armed, :road_shield_armed)
    assert_nil first[:dropped_part]
    assert_equal first.except(:duplicate), arena.move!(move: "attack", expected_round: 0).except(:duplicate)
    second = arena.move!(move: "attack", expected_round: 1)
    assert_equal ["blocked", "shield", 4, false], second.values_at(:outcome, :blocked_by, :player_hp, :shield_armed)
    third = arena.move!(move: "attack", expected_round: 2)
    assert_equal ["lose", 3], third.values_at(:outcome, :player_hp)
    assert_equal "shield", third[:dropped_part]["key"]
    assert_equal 3, battle.reload.enemy_max_hp
    next_mission = @learner.practice_sessions.create!(status: "completed")
    assert_not BattleArena.start!(@learner, next_mission).road_shield_armed?
  end

  test "full reset removes only this browser's drive and stale objects cannot recreate it" do
    run = start_drive
    other = Learner.create!
    other_mission = PracticePlanner.start!(other)
    other_mission.update!(cursor: 6)
    other_run = DinoDrive.new(other_mission).start!
    FullReset.reset!(@learner, confirmation: "1", reset_word: "RESET", shop_generation: 1, dinosaur_generation: 1)
    assert_not RoadRun.exists?(run.id)
    assert RoadRun.exists?(other_run.id)
    assert_raises(ActiveRecord::RecordNotFound) { @drive.start! }
    assert_raises(ActiveRecord::RecordNotFound) { finish(run, [], 24_000) }
  end

  private

  def start_drive
    @mission.update!(cursor: 6)
    @drive.start!
  end

  def finish(run, moves, elapsed)
    @drive.finish!(token: run.token, moves: moves, elapsed_ms: elapsed)
  end

  def winning_moves(run)
    lane = 1
    run.obstacles.filter_map do |rock|
      next unless lane == rock["lane"]
      lane = lane == 0 ? 1 : lane - 1
      { "at_ms" => rock["at_ms"] - 500, "lane" => lane }
    end
  end
end
