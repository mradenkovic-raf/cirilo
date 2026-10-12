require "test_helper"
require_relative "../services/exercise_helpers"

class AttemptsControllerTest < ActionDispatch::IntegrationTest
  include ExerciseHelpers
  test "JSON endpoint persists validated answers and prevents skipping ahead" do
    session = PracticePlanner.start!(test_learner)
    session.update!(cursor: 2)
    exercise = session.current_exercise
    post practice_session_attempts_path(session), params: {
      exercise_id: exercise.fetch("id"), answer: exercise.fetch("answer")
    }, as: :json
    assert_response :success
    assert response.parsed_body.fetch("correct")
    assert_equal 3, session.reload.cursor

    post practice_session_attempts_path(session), params: {
      exercise_id: session.exercises.last.fetch("id"), answer: "А"
    }, as: :json
    assert_response :conflict
    assert_equal 3, session.reload.cursor
  end

  test "malformed answers return a useful validation response" do
    session = PracticePlanner.start!(test_learner)
    session.update!(cursor: 2)
    post practice_session_attempts_path(session), params: {
      exercise_id: session.current_exercise.fetch("id"), answer: ["А"]
    }, as: :json
    assert_response :unprocessable_entity
    assert response.parsed_body.fetch("error").present?
    assert_equal 2, session.reload.cursor
  end

  test "malformed trace metrics return validation rather than a server error" do
    session = PracticePlanner.start!(test_learner)
    session.update!(cursor: session.exercises.index { |exercise| exercise["kind"] == "trace" })
    original_cursor = session.cursor
    post practice_session_attempts_path(session), params: {
      exercise_id: session.current_exercise.fetch("id"), trace_score: 100, trace_metrics: [1, 2]
    }, as: :json
    assert_response :unprocessable_entity
    assert_equal original_cursor, session.reload.cursor
  end

  test "nested writing payload grades every chosen letter and supplies word meaning" do
    test_learner.update!(completed_missions: 1)
    session = PracticePlanner.start!(test_learner)
    session.update!(cursor: session.exercises.index { |exercise| exercise["kind"] == "fill_letters" })
    exercise = session.current_exercise
    post practice_session_attempts_path(session), params: correct_attributes(exercise), as: :json
    assert_response :success
    body = response.parsed_body
    assert body.fetch("correct")
    assert_equal exercise["writing_letters"].length, body.fetch("letter_feedback").length
    assert body.fetch("letter_feedback").all? { |item| item.fetch("correct") }
    assert_equal exercise["word"], body.fetch("meaning").fetch("word")
  end

  test "malformed writing arrays cannot skip a required letter" do
    session = PracticePlanner.start!(test_learner)
    session.update!(cursor: session.exercises.index { |exercise| exercise["kind"] == "write_word" })
    exercise = session.current_exercise
    ["invalid", [1, 2], []].each do |payload|
      post practice_session_attempts_path(session), params: { exercise_id: exercise["id"], letter_traces: payload }, as: :json
      assert_response :unprocessable_entity
    end
    assert_equal 0, session.attempts.count
  end
end
