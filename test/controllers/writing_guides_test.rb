require "test_helper"
require_relative "../services/exercise_helpers"

class WritingGuidesTest < ActionDispatch::IntegrationTest
  include ExerciseHelpers

  test "saved word writing uses current guides without changing mission state or answers" do
    learner = test_learner
    session = PracticePlanner.start!(learner)
    letter = Curriculum.find("a")
    old_paths = [[[7, 7], [9, 9]]]

    %w[write_word fill_letters].product(%w[upper lower]).each do |kind, letter_case|
      writing = PracticePlanner.send(:exercise, letter, WordBank.for_letter(letter), kind, letter_case)
      writing.fetch("writing_letters").each do |target|
        ([target] + target.fetch("options", [])).each { |guide| guide["paths"] = old_paths.deep_dup }
      end
      session.update!(exercises: [planned_exercise("trace"), writing], cursor: 0)
      solve_current_exercise(session)
      DinoDrive.new(session).skip! if session.reload.drive_pending?
      saved_session = session.reload.attributes.deep_dup
      saved_learner = learner.reload.attributes.deep_dup
      saved_attempts = session.attempts.order(:id).map(&:attributes)

      get practice_session_path(session)
      assert_response :success
      assert_select "script#writing-data" do |scripts|
        displayed = JSON.parse(scripts.first.text)
        expected = writing.fetch("writing_letters").deep_dup
        expected.each do |target|
          ([target] + target.fetch("options", [])).each do |guide|
            guide["paths"] = Curriculum.find(guide.fetch("letter_id")).fetch("strokes").fetch(letter_case)
          end
        end
        assert_equal expected, displayed, "#{kind} #{letter_case} must refresh all guides and keep answers and options"
        refute_equal writing.fetch("writing_letters"), displayed
      end

      assert_equal saved_session, session.reload.attributes
      assert_equal saved_learner, learner.reload.attributes
      assert_equal saved_attempts, session.attempts.order(:id).map(&:attributes)
    end
  end

  test "display guides do not share mutable paths with saved exercises or the curriculum" do
    session = PracticePlanner.start!(test_learner)
    writing = planned_exercise("fill_letters")
    session.update!(exercises: [writing])
    saved = session.exercises.deep_dup
    curriculum = Curriculum.letters.deep_dup

    displayed = session.current_exercise_for_display
    displayed.fetch("writing_letters").each do |target|
      ([target] + target.fetch("options", [])).each { |guide| guide.fetch("paths").first.first[0] = -100 }
    end

    assert_equal saved, session.exercises
    assert_equal curriculum, Curriculum.letters
  end
end
