require "test_helper"

class ConcurrentBattleTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup { Learner.destroy_all }
  teardown { Learner.destroy_all }

  test "two start requests create one persistent battle" do
    learner = Learner.current
    session = learner.practice_sessions.create!(status: "completed")
    replies = concurrent do
      BattleArena.start!(Learner.find(learner.id), PracticeSession.find(session.id)).id
    end
    assert replies.all? { |reply| reply.is_a?(Integer) }, replies.inspect
    assert_equal 1, replies.uniq.size
    assert_equal 1, learner.battles.count
  end

  test "two tabs sending the same round only deal damage once" do
    learner = Learner.current
    session = learner.practice_sessions.create!(status: "completed")
    battle = BattleArena.start!(learner, session)
    replies = concurrent do
      BattleArena.new(Battle.find(battle.id), enemy_picker: -> { "feint" }).move!(move: "attack", expected_round: 0)
    end
    assert replies.all? { |reply| reply.is_a?(Hash) && reply[:success] }, replies.inspect
    assert_equal 1, replies.count { |reply| reply[:duplicate] }
    assert_equal 1, battle.reload.round
    assert_equal 2, battle.enemy_hp
    assert_equal 1, battle.turn_history.size
    assert_equal 0, learner.reload.xp
  end

  test "two identical goggles requests commit one enemy choice and consume one charge" do
    battle = equipped_battle
    draws = Queue.new
    replies = concurrent do
      BattleArena.new(Battle.find(battle.id), enemy_picker: -> { draws << true; "guard" })
        .power!(power: "goggles", expected_round: 0, expected_revision: 0)
    end
    assert replies.all? { |reply| reply.is_a?(Hash) && reply[:success] }, replies.inspect
    assert_equal 1, replies.count { |reply| reply[:duplicate] }
    assert_equal 1, draws.size
    assert_equal [0, 1, "guard"], battle.reload.values_at(:round, :action_revision, :next_enemy_move)
    assert replies.all? { |reply| reply[:revealed_enemy_move] == "guard" }
  end

  test "different powers racing on the same revision cannot both be consumed" do
    battle = equipped_battle
    actions = Queue.new
    %w[goggles shield].each { |power| actions << power }
    replies = concurrent do
      BattleArena.new(Battle.find(battle.id)).power!(power: actions.pop, expected_round: 0, expected_revision: 0)
    end
    assert_equal 1, replies.count { |reply| reply.is_a?(Hash) && reply[:success] }, replies.inspect
    assert_equal 1, replies.count { |reply| reply.is_a?(BattleArena::StaleMove) }, replies.inspect
    assert_equal 1, battle.reload.power_state.values.count { |power| power["used"] }
    assert_equal 1, battle.action_revision
    assert_equal 0, battle.round
  end

  test "a move racing with goggles resolves one action and stale response can be resumed" do
    battle = equipped_battle
    actions = Queue.new
    %w[move goggles].each { |action| actions << action }
    replies = concurrent do
      arena = BattleArena.new(Battle.find(battle.id), enemy_picker: -> { "feint" })
      if actions.pop == "move"
        arena.move!(move: "attack", expected_round: 0, expected_revision: 0)
      else
        arena.power!(power: "goggles", expected_round: 0, expected_revision: 0)
      end
    end
    assert_equal 1, replies.count { |reply| reply.is_a?(Hash) && reply[:success] }, replies.inspect
    assert_equal 1, replies.count { |reply| reply.is_a?(BattleArena::StaleMove) }, replies.inspect
    assert_equal 1, battle.reload.action_revision
    assert_equal battle.round, battle.turn_history.length
    assert_equal 0, battle.learner.xp
  end

  private

  def equipped_battle
    learner = Learner.current
    [7, 11, 12].each do |position|
      mission = learner.practice_sessions.create!(status: "completed")
      learner.part_unlocks.create!(practice_session: mission, position: position,
        part_key: Curriculum.part_at(position).fetch("id"))
    end
    BattleArena.start!(learner, learner.practice_sessions.create!(status: "completed"))
  end

  def concurrent
    gate = Queue.new
    replies = Queue.new
    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          gate.pop
          replies << yield
        rescue StandardError => error
          replies << error
        end
      end
    end
    2.times { gate << true }
    threads.each(&:join)
    2.times.map { replies.pop }
  end
end
