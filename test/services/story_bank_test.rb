require "test_helper"
require_relative "exercise_helpers"

class StoryBankTest < ActiveSupport::TestCase
  include ExerciseHelpers

  test "all twelve commands require both the noun and size action or place" do
    dimensions = []
    sentences = []
    12.times do |variation|
      task = StoryBank.exercise(variation: variation)
      choices = task.fetch("choices")
      assert_equal 4, choices.length
      assert_equal 4, choices.map { |item| item.fetch("scene") }.uniq.length
      assert_equal choices.map { |item| item.fetch("value") }, task.fetch("options")
      correct = choices.find { |item| item.fetch("value") == task.fetch("answer") }.fetch("scene")
      dimension = task.fetch("story_dimension")
      assert_equal 2, choices.count { |item| item.fetch("scene").fetch("object") == correct.fetch("object") }
      assert_equal 2, choices.count { |item| item.fetch("scene").fetch(dimension) == correct.fetch(dimension) }
      assert_not_includes task.fetch("prompt"), task.fetch("story_sentence")
      assert_nil task["word"]
      dimensions << dimension; sentences << task.fetch("story_sentence")
    end
    assert_equal %w[action place size], dimensions.uniq.sort
    assert_equal 12, sentences.uniq.length
  end

  test "story error requires recovery and pays no XP or letter mastery until correct answer" do
    learner = Learner.current
    session = PracticePlanner.start!(learner)
    session.update!(cursor: session.exercises.index { |item| item["kind"] == "story_action" })
    exercise = session.current_exercise
    before = learner.letter_progresses.find_by!(letter_id: exercise.fetch("letter_id")).attributes
    result = AttemptRecorder.new(session).submit!(exercise_id: exercise.fetch("id"), answer: (exercise.fetch("options") - [exercise.fetch("answer")]).first)
    assert_not result.fetch(:correct)
    assert result.fetch(:recovery_required)
    assert_equal 0, learner.reload.xp
    assert_equal 13, session.reload.total_exercises
    assert_equal before, learner.letter_progresses.find_by!(letter_id: exercise.fetch("letter_id")).attributes
    assert_equal 0, LetterConfusion.count
    solve_current_exercise(session)
    assert_equal exercise.fetch("id"), session.reload.current_exercise.fetch("id")
    result = solve_current_exercise(session)
    assert result.fetch(:correct)
    assert_equal 10, result.fetch(:xp_earned)
  end

  test "new mission with a story remains twelve paid tasks and 145 XP" do
    session = PracticePlanner.start!(Learner.current)
    assert_equal 1, session.exercises.count { |item| item["kind"] == "story_action" }
    complete_practice_session(session)
    assert_equal 12, session.reload.attempts.count
    assert_equal 145, session.earned_xp
    assert_equal 145, session.learner.reload.xp
  end
end
