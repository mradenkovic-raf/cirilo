require "test_helper"
require_relative "exercise_helpers"

class SchoolLearningTest < ActiveSupport::TestCase
  include ExerciseHelpers

  test "book order defaults and validation are explicit" do
    assert_equal %w[А М И Т О Н С Е Р Ј У Ш Л Љ З В Г П К Д Б Њ Х Ж Ч Ћ Ф Ц Џ Ђ], SchoolCurriculum.letters.map { |letter| letter.fetch("upper") }
    assert_equal %w[a m i t o n s e], Learner.new.school_letter_ids
    assert Learner.new.school_mode?
    assert_not Learner.new(school_letter_ids: []).valid?
    assert_not Learner.new(school_letter_ids: ["a", "fake"]).valid?
    assert_not Learner.new(learning_mode: "other").valid?
  end

  test "first mistake recovery and its retries keep the mission scope after settings change" do
    learner = Learner.create!
    session = PracticePlanner.start!(learner)
    original = session.current_exercise
    assert_equal "read_word", original.fetch("kind")
    learner.update!(learning_mode: "full", school_letter_ids: SchoolCurriculum.through("dj"))
    wrong = (original.fetch("options") - [original.fetch("answer")]).first
    response = AttemptRecorder.new(session).submit!(exercise_id: original.fetch("id"), answer: wrong)
    assert response.fetch(:recovery_required)
    recovery = session.reload.current_exercise
    assert recovery.fetch("review_only")
    assert_equal SchoolCurriculum.default_ids, session.school_letter_ids
    assert_known_exercise(recovery, session.school_letter_ids)
    solve_current_exercise(session)
    assert_equal original.fetch("id"), session.reload.current_exercise.fetch("id")
    result = solve_current_exercise(session)
    assert_equal "", result.fetch(:meaning).fetch(:sentence)
    assert SchoolWordBank.find(result.fetch(:meaning).fetch(:word))
  end

  test "copied composer recovery never draws new distractors from the full alphabet" do
    learner = Learner.create!
    session = PracticePlanner.start!(learner)
    composer = session.exercises.find { |exercise| exercise["kind"] == "build_word" }
    copy = AttemptRecorder.new(session).send(:recovery_copy, composer)
    assert_equal composer.fetch("tiles").sort, copy.fetch("tiles").sort
    assert_known_exercise(copy, session.school_letter_ids)
  end

  test "complete reset clears content history but keeps parent curriculum choices" do
    learner = Learner.create!(school_letter_ids: %w[a m i], learning_settings_revision: 2)
    PracticePlanner.start!(learner)
    FullReset.reset!(learner, confirmation: "1", reset_word: "RESET", shop_generation: 1, dinosaur_generation: 1)
    assert_empty learner.practice_sessions
    assert_equal %w[a m i], learner.reload.school_letter_ids
    assert_equal "school", learner.learning_mode
    assert_equal 3, learner.learning_settings_revision
  end

  private

  def assert_known_exercise(exercise, ids)
    %w[word answer broken_word sentence_pattern story_sentence].each do |field|
      assert SchoolCurriculum.known_text?(exercise[field], ids), "Unknown letter in #{field}: #{exercise[field]}"
    end
    %w[tiles options repair_options].each do |field|
      exercise.fetch(field, []).each { |value| assert SchoolCurriculum.known_text?(value, ids) }
    end
  end
end
