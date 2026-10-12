require "test_helper"
require_relative "exercise_helpers"

class ConfusionTrackerTest < ActiveSupport::TestCase
  include ExerciseHelpers

  setup do
    @learner = Learner.current
    @learner.letter_progresses.create!(letter_id: "p")
    @session = @learner.practice_sessions.create!(focus_letters: %w[p], exercises: [word_task])
  end

  test "one observed substitution is recorded once despite retries and recovery" do
    task = @session.current_exercise
    recorder = AttemptRecorder.new(@session)
    recorder.submit!(exercise_id: task.fetch("id"), answer: "РАС")
    pair = LetterConfusion.sole
    assert_equal "p", pair.expected_letter_id
    assert_equal "r", pair.chosen_letter_id
    assert_equal 1, pair.observations
    solve_current_exercise(@session)
    recorder.submit!(exercise_id: task.fetch("id"), answer: "РАС")
    assert_equal 1, pair.reload.observations
    recorder.submit!(exercise_id: task.fetch("id"), answer: "ПАС")
    assert_equal 0, pair.reload.independent_successes
  end

  test "assistance multiple substitutions and handwriting errors do not invent a letter confusion" do
    AttemptRecorder.new(@session).submit!(exercise_id: @session.current_exercise.fetch("id"), answer: "РАС", assisted: true)
    assert_equal 0, LetterConfusion.count
    task = word_task(tiles: %w[П А С Р О])
    @session.update!(exercises: [task], cursor: 0)
    AttemptRecorder.new(@session).submit!(exercise_id: task.fetch("id"), answer: "РОС")
    assert_equal 0, LetterConfusion.count
    trace = { "id" => SecureRandom.uuid, "version" => 4, "kind" => "trace", "letter_id" => "p", "case" => "upper", "target" => "П", "answer" => "П" }
    @session.update!(exercises: [trace], cursor: 0)
    attrs = correct_attributes(trace).merge(trace_score: 12)
    AttemptRecorder.new(@session).submit!(**attrs)
    assert_equal 0, LetterConfusion.count
  end

  test "a wrong missing-letter choice is direct evidence but a correct choice with poor drawing is not" do
    task = fill_task
    @session.update!(exercises: [task], cursor: 0)
    attrs = correct_attributes(task)
    attrs[:letter_traces].first[:score] = 10
    AttemptRecorder.new(@session).submit!(**attrs)
    assert_equal 0, LetterConfusion.count
    task = fill_task
    @session.update!(exercises: [task], cursor: 0)
    attrs = correct_attributes(task)
    attrs[:letter_traces].first[:letter] = "Р"
    AttemptRecorder.new(@session).submit!(**attrs)
    assert_equal ["p", "r"], LetterConfusion.sole.attributes.values_at("expected_letter_id", "chosen_letter_id")
  end

  test "two first independent successes must be in different missions and duplicate requests cannot clear faster" do
    pair = observed_pair
    tasks = 2.times.map { word_task(checks: true) }
    @session.update!(exercises: tasks)
    recorder = AttemptRecorder.new(@session)
    tasks.each { |task| recorder.submit!(exercise_id: task.fetch("id"), answer: "ПАС") }
    recorder.submit!(exercise_id: tasks.last.fetch("id"), answer: "ПАС")
    assert_equal 1, pair.reload.independent_successes
    assert_includes LetterConfusion.active, pair
    second = @learner.practice_sessions.create!(focus_letters: %w[p], exercises: [word_task(checks: true)])
    solve_current_exercise(second)
    assert_equal 2, pair.reload.independent_successes
    assert_not_includes LetterConfusion.active, pair
    third = @learner.practice_sessions.create!(focus_letters: %w[p], exercises: [word_task])
    AttemptRecorder.new(third).submit!(exercise_id: third.current_exercise.fetch("id"), answer: "РАС")
    assert_equal 0, pair.reload.independent_successes
    assert_equal 2, pair.observations
  end

  test "guided missing-letter and tracing work cannot clear independent confusion evidence" do
    pair = observed_pair
    task = fill_task.merge("confusion_checks" => [{ "expected" => "p", "chosen" => "r" }])
    @session.update!(exercises: [task])
    solve_current_exercise(@session)
    assert_equal 0, pair.reload.independent_successes
  end

  test "planner prioritizes the recorded pair and carries its alternative through different tasks" do
    @session.update!(status: "completed")
    %w[a m r].each { |id| @learner.letter_progresses.create!(letter_id: id) }
    observed_pair
    @learner.update!(completed_missions: 1)
    mission = PracticePlanner.start!(@learner)
    assert_equal %w[p r], mission.focus_letters.first(2)
    trace = mission.exercises.find { |item| item["kind"] == "trace" && item["letter_id"] == "p" }
    assert_equal %w[П Р], trace.fetch("contrast_letters").map(&:upcase)
    recall = mission.exercises.select { |item| item["confusion_checks"] }
    assert recall.any?
    recall.each do |task|
      assert_includes task.fetch("word"), "П"
      assert_includes task.fetch("tiles"), "Р"
      assert_equal task.fetch("word").length + 2, task.fetch("tiles").length
    end
    filling = mission.exercises.find { |item| item["kind"] == "fill_letters" && item["letter_id"] == "p" }
    target = filling.fetch("writing_letters").find { |item| item["letter_id"] == "p" }
    assert_includes target.fetch("options").map { |item| item.fetch("target").upcase }, "Р"
    before = mission.exercises
    assert_equal before, PracticePlanner.start!(@learner).exercises
  end

  test "shop and dinosaur resets preserve observations and independent evidence" do
    pair = observed_pair
    pair.update!(independent_successes: 1, last_success_session_id: @session.id, last_success_at: Time.current)
    evidence = pair.attributes
    @learner.update!(xp: 120, dino_color: "blue")
    DinoReset.reset!(@learner, confirmation: "1", generation: @learner.dinosaur_generation)
    assert_equal evidence, pair.reload.attributes
    ShopReset.reset!(@learner, confirmation: "1", reset_word: "RESET", generation: @learner.shop_generation)
    assert_equal evidence, pair.reload.attributes
  end

  private

  def observed_pair
    LetterConfusion.create!(learner: @learner, expected_letter_id: "p", chosen_letter_id: "r", observations: 1, last_mistake_at: Time.current)
  end

  def word_task(tiles: %w[П А С Р О], checks: false)
    { "id" => SecureRandom.uuid, "version" => 4, "kind" => "build_word", "letter_id" => "p", "case" => "upper", "word" => "ПАС", "answer" => "ПАС", "tiles" => tiles,
      "confusion_checks" => checks ? [{ "expected" => "p", "chosen" => "r" }] : [] }
  end

  def fill_task
    options = %w[p r a m].map do |id|
      letter = Curriculum.find(id)
      { "letter_id" => id, "target" => letter.fetch("upper"), "paths" => letter.fetch("strokes").fetch("upper") }
    end
    word_task.merge("kind" => "fill_letters", "writing_letters" => [options.first.merge("index" => 0, "options" => options)])
  end
end
