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

  test "twenty position sentences distinguish the relation while keeping the object and container identical" do
    nouns = { "apple" => "Јабука", "ball" => "Лопта" }
    phrases = {
      "backpack" => { "inside" => "у ранцу", "on" => "на ранцу", "beside" => "поред ранца",
        "in_front" => "испред ранца", "behind" => "иза ранца" },
      "box" => { "inside" => "у кутији", "on" => "на кутији", "beside" => "поред кутије",
        "in_front" => "испред кутије", "behind" => "иза кутије" }
    }
    expected = nouns.flat_map do |object, noun|
      phrases.flat_map do |anchor, positions|
        positions.map { |position, phrase| [[object, anchor, position], "#{noun} је #{phrase}."] }
      end
    end.to_h
    seen = {}

    20.times do |variation|
      task = StoryBank.position_exercise(variation: variation)
      choices = task.fetch("choices")
      assert_equal "position", task.fetch("story_dimension")
      assert_equal 4, choices.length
      assert_equal 4, task.fetch("options").uniq.length
      assert_equal choices.map { |choice| choice.fetch("value") }, task.fetch("options")
      assert_equal 1, choices.count { |choice| choice.fetch("value") == task.fetch("answer") }
      correct = choices.find { |choice| choice.fetch("value") == task.fetch("answer") }.fetch("scene")
      key = correct.values_at("object", "anchor", "position")
      assert_equal expected.fetch(key), task.fetch("story_sentence")
      assert_not seen.key?(key), "Repeated position sentence in the twenty-task rotation"
      seen[key] = task.fetch("story_sentence")

      assert_equal 4, choices.map { |choice| choice.fetch("scene").fetch("position") }.uniq.length
      contrasted_positions = %w[inside on].include?(correct.fetch("position")) ? %w[inside on] : %w[in_front behind]
      if contrasted_positions.include?(correct.fetch("position"))
        contrasted_positions.each do |position|
          assert_includes choices.map { |choice| choice.fetch("scene").fetch("position") }, position
        end
      end
      choices.each do |choice|
        scene = choice.fetch("scene")
        assert_match(/\AS\d+\z/, choice.fetch("value"))
        assert_equal "position", scene.fetch("dimension")
        assert_equal correct.fetch("object"), scene.fetch("object")
        assert_equal correct.fetch("anchor"), scene.fetch("anchor")
        assert_includes phrases.fetch(scene.fetch("anchor")).keys, scene.fetch("position")
        next if choice.fetch("value") == task.fetch("answer")
        assert_not_equal correct.fetch("position"), scene.fetch("position")
      end
      assert_not_includes task.fetch("prompt"), task.fetch("story_sentence")
      assert_nil task["word"]
    end
    assert_equal expected, seen
  end

  test "position rotation can continue beyond its first twenty sentences" do
    20.times do |variation|
      original = StoryBank.position_exercise(variation: variation)
      repeated = StoryBank.position_exercise(variation: variation + 20)
      assert_equal original.fetch("story_sentence"), repeated.fetch("story_sentence")
      target = ->(task) { task.fetch("choices").find { |choice| choice.fetch("value") == task.fetch("answer") }.fetch("scene") }
      assert_equal target.call(original), target.call(repeated)
    end
  end

  test "story error requires recovery and pays no XP or letter mastery until correct answer" do
    learner = test_learner
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
    after_recovery = learner.letter_progresses.order(:id).map(&:attributes)
    result = solve_current_exercise(session)
    assert result.fetch(:correct)
    assert_equal 10, result.fetch(:xp_earned)
    assert_equal after_recovery, learner.letter_progresses.order(:id).map(&:attributes)
    duplicate = AttemptRecorder.new(session).submit!(exercise_id: exercise.fetch("id"), answer: exercise.fetch("answer"))
    assert duplicate.fetch(:duplicate)
    assert_equal 0, duplicate.fetch(:xp_earned)
    assert_equal 10, learner.reload.xp
  end

  test "new mission with two stories remains twelve paid tasks and 145 XP" do
    session = PracticePlanner.start!(test_learner)
    assert_equal 2, session.exercises.count { |item| item["kind"] == "story_action" }
    complete_practice_session(session)
    assert_equal 12, session.reload.attempts.count
    assert_equal 145, session.earned_xp
    assert_equal 145, session.learner.reload.xp
  end
end
