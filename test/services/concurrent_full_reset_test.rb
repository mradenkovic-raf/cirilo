require "test_helper"
require_relative "exercise_helpers"

class ConcurrentFullResetTest < ActiveSupport::TestCase
  include ExerciseHelpers
  self.use_transactional_tests = false

  setup { Learner.destroy_all }
  teardown { Learner.destroy_all }

  test "two simultaneous full resets with the same tokens apply once" do
    learner = test_learner
    learner.update!(xp: 500, completed_missions: 8)
    reset = -> { reset_all(learner.id) }
    results = together(reset, reset)
    assert_equal 1, results.count { |result| result.is_a?(Learner) }, results.inspect
    assert_equal 1, results.count { |result| result.is_a?(FullReset::InvalidRequest) }, results.inspect
    assert_equal [0, 0, 2, 2], learner.reload.values_at(:xp, :completed_missions, :shop_generation, :dinosaur_generation)
  end

  test "an already loaded final answer racing restart cannot revive rewards or rescue friends" do
    learner = test_learner
    session = PracticePlanner.start!(learner)
    (session.total_exercises - 1).times { solve_current_exercise(session) }
    recorder = AttemptRecorder.new(session)
    exercise = session.reload.current_exercise
    recorder.memorize!(exercise_id: exercise.fetch("id")) if exercise.fetch("kind") == "memory_word"
    results = together(
      -> { recorder.submit!(**correct_attributes(exercise)) },
      -> { reset_all(learner.id) }
    )
    assert results.all? { |result| result.is_a?(Learner) || result.is_a?(Hash) || result.is_a?(ActiveRecord::RecordNotFound) }, results.inspect
    assert_equal 1, results.count { |result| result.is_a?(Learner) }
    assert_equal [0, 0], learner.reload.values_at(:xp, :completed_missions)
    assert_empty learner.practice_sessions
    assert_empty learner.attempts
    assert_empty learner.part_unlocks
    assert_empty learner.letter_progresses
  end

  test "an already loaded battle turn racing restart cannot leave an orphan battle" do
    learner = test_learner
    session = learner.practice_sessions.create!(status: "completed", completed_at: Time.current)
    battle = BattleArena.start!(learner, session)
    arena = BattleArena.new(battle, enemy_picker: -> { "feint" })
    results = together(
      -> { arena.move!(move: "attack", expected_round: 0) },
      -> { reset_all(learner.id) }
    )
    assert results.all? { |result| result.is_a?(Learner) || result.is_a?(Hash) || result.is_a?(ActiveRecord::RecordNotFound) }, results.inspect
    assert_equal 1, results.count { |result| result.is_a?(Learner) }
    assert_empty learner.reload.battles
    assert_empty learner.practice_sessions
    assert_equal 0, learner.completed_missions
  end

  private

  def reset_all(id)
    FullReset.reset!(Learner.find(id), confirmation: "1", reset_word: "RESET", shop_generation: 1, dinosaur_generation: 1)
  end

  def together(*jobs)
    gate, results = Queue.new, Queue.new
    workers = jobs.map do |job|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          gate.pop
          results << job.call
        rescue StandardError => error
          results << error
        end
      end
    end
    jobs.length.times { gate << true }
    workers.each(&:join)
    jobs.length.times.map { results.pop }
  end
end
