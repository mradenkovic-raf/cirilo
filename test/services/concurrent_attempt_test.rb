require "test_helper"
require_relative "exercise_helpers"

class ConcurrentAttemptTest < ActiveSupport::TestCase
  include ExerciseHelpers
  self.use_transactional_tests = false

  setup do
    Learner.destroy_all
  end

  teardown do
    Learner.destroy_all
  end

  test "two devices submitting the same answer award progress once" do
    learner = Learner.current
    session = PracticePlanner.start!(learner)
    exercise = session.current_exercise
    replies = concurrent_replies(session, exercise)
    assert replies.all? { |result| result.is_a?(Hash) && result[:correct] }, replies.inspect
    assert_equal 1, replies.count { |result| result[:duplicate] }
    assert_equal 10, learner.reload.xp
    assert_equal 1, session.reload.cursor
    assert_equal 1, session.attempts.count
  end

  test "simultaneous final answers issue only one part and completion bonus" do
    learner = Learner.current
    session = PracticePlanner.start!(learner)
    session.update!(cursor: 11, earned_xp: 110)
    learner.update!(xp: 110)
    replies = concurrent_replies(session, session.current_exercise)
    assert replies.all? { |result| result.is_a?(Hash) && result[:completed] }, replies.inspect
    assert_equal 145, learner.reload.xp
    assert_equal 145, session.reload.earned_xp
    assert_equal 1, learner.completed_missions
    assert_equal 1, learner.part_unlocks.count
  end

  private

  def concurrent_replies(session, exercise)
    AttemptRecorder.new(session).memorize!(exercise_id: exercise.fetch("id")) if exercise.fetch("kind") == "memory_word"
    gate = Queue.new
    results = Queue.new
    workers = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          recorder = AttemptRecorder.new(PracticeSession.find(session.id))
          gate.pop
          results << recorder.submit!(**correct_attributes(exercise))
        rescue StandardError => error
          results << error
        end
      end
    end
    2.times { gate << true }
    workers.each(&:join)
    2.times.map { results.pop }
  end
end
