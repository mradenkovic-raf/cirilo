require "test_helper"
require_relative "exercise_helpers"

class AttemptRecorderTest < ActiveSupport::TestCase
  include ExerciseHelpers

  setup do
    @learner = test_learner
    @session = PracticePlanner.start!(@learner)
  end

  test "a mistake inserts a zero XP recovery before the original task" do
    @session.update!(cursor: 2)
    original = @session.current_exercise.deep_dup
    result = submit_wrong(original)
    assert_not result[:correct]
    assert result[:recovery_required]
    assert_equal 2, @session.reload.cursor
    assert_equal 13, @session.total_exercises
    recovery = @session.current_exercise
    assert_equal original["id"], recovery["recovery_of"]
    assert_equal original["id"], @session.exercises[3]["id"]
    assert_not_equal original["id"], recovery["id"]
    assert recovery["review_only"]
    assert recovery["extra_review"]
    assert_equal 0, @learner.reload.xp
    assert_raises(AttemptRecorder::StaleExercise) do
      AttemptRecorder.new(@session).submit!(**correct_attributes(original))
    end

    recovered = solve_current_exercise(@session)
    assert recovered[:correct]
    assert_equal 0, recovered[:xp_earned]
    assert_equal original["id"], @session.reload.current_exercise["id"]
    good = solve_current_exercise(@session)
    assert good[:correct]
    assert_equal 10, good[:xp_earned]
    progress = @learner.letter_progresses.find_by!(letter_id: original["letter_id"])
    assert_equal 0, progress.review_level
    assert_nil progress.last_reviewed_at
    replay = AttemptRecorder.new(@session).submit!(**correct_attributes(original))
    assert replay[:duplicate]
    assert_equal 0, replay[:xp_earned]
    assert_equal 10, @learner.reload.xp
  end

  test "recovery mistakes and repeated original mistakes do not add another penalty" do
    @session.update!(cursor: 2)
    original = @session.current_exercise.deep_dup
    submit_wrong(original)
    recovery = @session.reload.current_exercise
    2.times do
      result = submit_wrong(recovery)
      assert_not result[:recovery_required]
      assert_equal 13, @session.reload.total_exercises
      assert_equal recovery["id"], @session.current_exercise["id"]
    end
    recovery_progress = @learner.letter_progresses.find_by!(letter_id: recovery["letter_id"])
    assert_equal 0, recovery_progress.incorrect_count
    solve_current_exercise(@session)
    result = submit_wrong(original)
    assert_not result[:recovery_required]
    assert_equal 13, @session.reload.total_exercises
    original_progress = @learner.letter_progresses.find_by!(letter_id: original["letter_id"])
    assert_equal 1, original_progress.incorrect_count
  end

  test "only three normal task mistakes can insert recovery tasks" do
    4.times do |index|
      exercise = @session.reload.current_exercise
      result = submit_wrong(exercise)
      assert_equal index < 3, result[:recovery_required]
      solve_current_exercise(@session) if result[:recovery_required]
      solve_current_exercise(@session)
    end
    assert_equal 15, @session.reload.total_exercises
    assert_equal 3, @session.exercises.count { |item| item["recovery_of"] }
    assert_equal 40, @learner.reload.xp
  end

  test "full mission issues one part bonus and meaning for every successful word" do
    original_last = @session.exercises.last.deep_dup
    until @session.reload.completed?
      exercise = @session.current_exercise
      result = solve_current_exercise(@session)
      assert result[:correct]
      if exercise["word"].present?
        assert_equal exercise["word"], result[:meaning][:word]
        assert result[:meaning][:emoji].present?
        assert_includes result[:meaning][:sentence], exercise["word"].downcase
        assert_not_includes result[:meaning][:sentence], "▢"
      else
        assert_nil result[:meaning]
      end
    end
    assert_equal 145, @learner.reload.xp
    assert_equal 145, @session.earned_xp
    assert_equal "boots", @session.part_unlock.part_key
    replay = AttemptRecorder.new(@session).submit!(**correct_attributes(original_last))
    assert replay[:duplicate]
    assert replay[:completed]
    assert_equal 0, replay[:xp_earned]
    assert_equal 1, @learner.part_unlocks.count
    assert_not_equal @session.id, PracticePlanner.start!(@learner).id
  end

  test "composed answers respect tile multiplicity and accept lowercase" do
    use_kind("build_word")
    exercise = @session.current_exercise
    recorder = AttemptRecorder.new(@session)
    assert_raises(AttemptRecorder::InvalidSubmission) do
      recorder.submit!(exercise_id: exercise["id"], answer: exercise["answer"][0] * exercise["answer"].length)
    end
    assert_equal 0, @session.attempts.count
    result = recorder.submit!(exercise_id: exercise["id"], answer: exercise["answer"].downcase)
    assert result[:correct]
    assert_equal 1, @learner.letter_progresses.find_by!(letter_id: exercise["letter_id"]).review_level
  end

  test "every written letter must be submitted once with a valid allowed choice" do
    use_kind("write_word")
    exercise = @session.current_exercise
    valid = correct_attributes(exercise)
    recorder = AttemptRecorder.new(@session)
    malformed = [nil, [], valid[:letter_traces].drop(1), [1, 2, 3]]
    duplicate = valid[:letter_traces].deep_dup
    duplicate[1][:index] = duplicate[0][:index]
    malformed << duplicate
    unknown_letter = valid[:letter_traces].deep_dup
    unknown_letter[0][:letter] = "A"
    malformed << unknown_letter
    malformed.each do |traces|
      assert_raises(AttemptRecorder::InvalidSubmission) do
        recorder.submit!(exercise_id: exercise["id"], letter_traces: traces)
      end
    end
    assert_equal 0, @session.attempts.count
    assert_equal 1, @session.reload.cursor
  end

  test "excellent scores for other letters cannot compensate for one missing shape" do
    use_kind("write_word")
    exercise = @session.current_exercise
    attrs = correct_attributes(exercise)
    attrs[:letter_traces].each { |trace| trace[:score] = 100 }
    attrs[:letter_traces].last[:score] = 20
    result = AttemptRecorder.new(@session).submit!(**attrs)
    assert_not result[:correct]
    assert_equal 20, result[:score]
    assert_equal 1, result[:letter_feedback].count { |item| !item["correct"] }
    assert result[:recovery_required]
    assert_equal 0, @learner.reload.xp
  end

  test "a well traced wrong letter does not fill a missing letter correctly" do
    use_kind("fill_letters")
    exercise = @session.current_exercise
    attrs = correct_attributes(exercise)
    target = exercise["writing_letters"].first
    wrong_choice = target["options"].find { |option| option["target"] != target["target"] }
    attrs[:letter_traces].first[:letter] = wrong_choice["target"].downcase
    result = AttemptRecorder.new(@session).submit!(**attrs)
    assert_not result[:correct]
    assert_not result[:letter_feedback].first["correct"]
    assert_not result[:letter_feedback].first.key?("target")
    assert_equal 0, @learner.reload.xp
  end

  test "whole word and missing letter handwriting are motor practice not recall" do
    %w[write_word fill_letters].each do |kind|
      use_kind(kind)
      exercise = @session.current_exercise
      result = solve_current_exercise(@session)
      assert result[:correct]
      progress = @learner.letter_progresses.find_by!(letter_id: exercise["letter_id"])
      assert_equal 0, progress.review_level
      assert_nil progress.last_reviewed_at
    end
  end

  test "memory cannot be submitted before hiding and hiding survives reload" do
    use_kind("memory_word")
    exercise = @session.current_exercise
    assert_raises(AttemptRecorder::InvalidSubmission) do
      AttemptRecorder.new(@session).submit!(**correct_attributes(exercise))
    end
    recorder = AttemptRecorder.new(@session)
    2.times { assert recorder.memorize!(exercise_id: exercise["id"])[:memory_hidden] }
    assert @session.reload.current_exercise["memory_hidden"]
    assert_equal 12, @session.total_exercises
    assert_equal 0, @session.attempts.count
    assert_equal 0, @learner.reload.xp
    result = AttemptRecorder.new(PracticeSession.find(@session.id)).submit!(**correct_attributes(exercise))
    assert result[:correct]
  end

  test "a copied memory recovery starts with a fresh study phase" do
    memory = @session.exercises.find { |item| item["kind"] == "memory_word" }.deep_dup
    memory["memory_hidden"] = true
    reading = planned_exercise("read_word", letter_id: @session.focus_letters.first)
    @session.update!(exercises: [memory, reading], cursor: 1)
    submit_wrong(reading)
    recovery = @session.reload.current_exercise
    assert_equal "memory_word", recovery["kind"]
    assert_equal false, recovery["memory_hidden"]
    assert_equal reading["id"], recovery["recovery_of"]
    result = solve_current_exercise(@session)
    assert result[:correct]
    assert_equal 0, result[:xp_earned]
  end

  test "empty drawing fails and malformed metrics are rejected without attempts" do
    exercise = @session.current_exercise
    recorder = AttemptRecorder.new(@session)
    assert_raises(AttemptRecorder::InvalidSubmission) do
      recorder.submit!(exercise_id: exercise["id"], trace_score: "NaN", trace_metrics: {})
    end
    assert_equal 0, @session.attempts.count
    empty = recorder.submit!(exercise_id: exercise["id"], trace_score: 100,
      trace_metrics: { coverage: 1, precision: 1, points: 0, drawnLength: 0, guideLength: 200 })
    assert_not empty[:correct]
    assert empty[:recovery_required]
    assert_equal 0, @learner.reload.xp
    solve_current_exercise(@session)
    valid = solve_current_exercise(@session)
    assert valid[:correct]
    assert_equal 10, @learner.reload.xp
  end

  test "legacy answers retain correctness and rewards without claiming new word recall" do
    old = { "id" => "legacy-one", "kind" => "case_match", "letter_id" => "a", "answer" => "а", "options" => %w[а м и о] }
    @session.update!(exercises: [old] + @session.exercises.drop(1))
    result = AttemptRecorder.new(@session).submit!(exercise_id: old["id"], answer: "а")
    assert result[:correct]
    assert_equal 0, @learner.letter_progresses.find_by!(letter_id: "a").review_level
    assert_equal 10, @learner.reload.xp
  end

  test "reward numbering follows the current collection after dinosaur reset" do
    @learner.update!(completed_missions: 9)
    complete_practice_session(@session)
    assert_equal 10, @learner.reload.completed_missions
    assert_equal "boots", @session.part_unlock.part_key
    assert_equal 1, @session.part_unlock.position
  end

  private

  def use_kind(kind)
    index = @session.exercises.index { |exercise| exercise["kind"] == kind }
    unless index
      @session.update!(exercises: @session.exercises + [planned_exercise(kind, letter_id: @session.focus_letters.first)])
      index = @session.exercises.length - 1
    end
    @session.update!(cursor: index)
  end

  def submit_wrong(exercise)
    recorder = AttemptRecorder.new(@session)
    recorder.memorize!(exercise_id: exercise["id"]) if exercise["kind"] == "memory_word"
    attrs = correct_attributes(exercise)
    case exercise["kind"]
    when "trace" then attrs[:trace_score] = 20
    when "write_word", "fill_letters" then attrs[:letter_traces].first[:score] = 20
    when "build_word", "memory_word" then attrs[:answer] = exercise["answer"].chars.rotate.join
    else attrs[:answer] = (exercise["options"] - [exercise["answer"]]).first
    end
    recorder.submit!(**attrs)
  end
end
