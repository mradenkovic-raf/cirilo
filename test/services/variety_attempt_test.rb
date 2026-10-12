require "test_helper"
require_relative "exercise_helpers"

class VarietyAttemptTest < ActiveSupport::TestCase
  include ExerciseHelpers

  setup do
    @learner = Learner.current
    @session = PracticePlanner.start!(@learner)
  end

  test "repair rejects unchanged multiple-change unknown-tile and malformed answers without an attempt" do
    task = use_kind("repair_word")
    broken = task.fetch("broken_word")
    foreign = broken.dup
    foreign[0] = "A"
    multiple = broken.dup
    multiple[0] = broken[0] == "А" ? "Б" : "А"
    multiple[1] = broken[1] == "А" ? "Б" : "А"
    [nil, {}, [], "", broken, broken[0...-1], foreign, multiple, "#{broken}А"].each do |answer|
      assert_raises(AttemptRecorder::InvalidSubmission) { submit(task, answer) }
    end
    assert_equal 0, @session.attempts.count
    assert_equal 0, @learner.reload.xp
    result = submit(task, task.fetch("answer").downcase)
    assert result.fetch(:correct)
    assert_equal 10, result.fetch(:xp_earned)
    assert_equal task.fetch("word"), result.fetch(:meaning).fetch(:word)
  end

  test "well formed wrong repair needs recovery then correct answer pays only once" do
    task = use_kind("repair_word")
    wrong = task.fetch("broken_word").dup
    index = wrong.chars.each_index.find { |offset| wrong[offset] != task.fetch("answer")[offset] }
    wrong[index] = (task.fetch("repair_options") - [wrong[index], task.fetch("answer")[index]]).first
    result = submit(task, wrong)
    assert_not result.fetch(:correct)
    assert result.fetch(:recovery_required)
    assert_equal task.fetch("id"), @session.reload.current_exercise.fetch("recovery_of")
    assert_equal 0, solve_current_exercise(@session).fetch(:xp_earned)
    assert_equal task, @session.reload.current_exercise
    assert_equal 10, submit(task, task.fetch("answer")).fetch(:xp_earned)
    assert submit(task, task.fetch("answer")).fetch(:duplicate)
    assert_equal 10, @learner.reload.xp
    progress = @learner.letter_progresses.find_by!(letter_id: task.fetch("letter_id"))
    assert_equal 0, progress.review_level
    assert_equal 0, LetterConfusion.count
  end

  test "pairs require a complete bijection and do not award XP for partial matches" do
    task = use_kind("word_pairs")
    [nil, {}, [], "", "P1", "P1,P2", "P1,P1,P3", "P1,P2,P4", "P1,P2,P3,", "P1, P2,P3", "W1,W2,W3"].each do |answer|
      assert_raises(AttemptRecorder::InvalidSubmission) { submit(task, answer) }
    end
    assert_equal 0, @session.attempts.count
    assert_equal 0, @learner.reload.xp
    before = @learner.letter_progresses.order(:id).map(&:attributes)
    wrong = task.fetch("answer").split(",").rotate.join(",")
    result = submit(task, wrong)
    assert_not result.fetch(:correct)
    assert result.fetch(:recovery_required)
    assert_nil result.fetch(:meaning)
    assert_equal before, @learner.letter_progresses.order(:id).map(&:attributes)
    solve_current_exercise(@session)
    after_recovery = @learner.letter_progresses.order(:id).map(&:attributes)
    result = submit(task, task.fetch("answer"))
    assert result.fetch(:correct)
    assert_equal 10, result.fetch(:xp_earned)
    assert_nil result.fetch(:meaning)
    assert_equal after_recovery, @learner.letter_progresses.order(:id).map(&:attributes)
    assert_equal 0, submit(task, task.fetch("answer")).fetch(:xp_earned)
    assert_equal 10, @learner.reload.xp
  end

  test "pair recovery shuffles display while retaining the stored word to picture mapping" do
    pairs = use_kind("word_pairs").deep_dup
    next_task = @session.exercises.find { |item| item.fetch("kind") == "picture_word" }.deep_dup
    @session.update!(exercises: [pairs, next_task], cursor: 1)
    submit(next_task, (next_task.fetch("options") - [next_task.fetch("answer")]).first)
    recovery = @session.reload.current_exercise
    assert_equal "word_pairs", recovery.fetch("kind")
    assert_equal pairs.fetch("answer"), recovery.fetch("answer")
    assert_equal pairs.fetch("pair_words"), recovery.fetch("pair_words")
    assert_not_equal pairs.fetch("pair_pictures"), recovery.fetch("pair_pictures")
    assert_not_equal pairs.fetch("answer").split(","), recovery.fetch("pair_pictures").map { |item| item.fetch("id") }
    assert_equal 0, solve_current_exercise(@session).fetch(:xp_earned)
  end

  test "new single word kinds measure only the focus letter and honor recall spacing" do
    %w[picture_word repair_word].each do |kind|
      task = use_kind(kind)
      result = submit(task, task.fetch("answer"))
      assert result.fetch(:correct)
      assert_equal 10, result.fetch(:xp_earned)
    end
    focus = @session.exercises.find { |task| task.fetch("kind") == "picture_word" }.fetch("letter_id")
    assert_equal 1, @learner.letter_progresses.find_by!(letter_id: focus).review_level
    assert @learner.letter_progresses.where.not(letter_id: focus).all? { |progress| progress.review_level.zero? }
  end

  private

  def use_kind(kind)
    @session.update!(cursor: @session.exercises.index { |task| task.fetch("kind") == kind })
    @session.current_exercise
  end

  def submit(task, answer)
    AttemptRecorder.new(@session).submit!(exercise_id: task.fetch("id"), answer: answer)
  end
end
