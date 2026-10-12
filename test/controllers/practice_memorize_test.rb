require "test_helper"

class PracticeMemorizeTest < ActionDispatch::IntegrationTest
  setup do
    @session = PracticePlanner.start!(Learner.current)
    @session.update!(cursor: @session.exercises.index { |item| item["kind"] == "memory_word" })
    @exercise = @session.current_exercise
  end

  test "memorize persistently hides the word and repeated requests do not advance anything" do
    2.times do
      post memorize_practice_session_path(@session), params: { exercise_id: @exercise["id"] }, as: :json
      assert_response :success
      assert response.parsed_body.fetch("memory_hidden")
    end
    assert @session.reload.current_exercise["memory_hidden"]
    assert_equal 0, Learner.current.xp
    assert_equal 0, @session.attempts.count
    assert_equal 12, @session.total_exercises
    get practice_session_path(@session)
    assert_response :success
    assert_select "[data-memory-study]:not([hidden])", 0
    assert_select "[data-composer]:not([hidden])", 1
  end

  test "memory answer before memorize is rejected and after memorize is accepted" do
    post practice_session_attempts_path(@session), params: { exercise_id: @exercise["id"], answer: @exercise["answer"] }, as: :json
    assert_response :unprocessable_entity
    assert_equal 0, @session.attempts.count
    post memorize_practice_session_path(@session), params: { exercise_id: @exercise["id"] }, as: :json
    assert_response :success
    post practice_session_attempts_path(@session), params: { exercise_id: @exercise["id"], answer: @exercise["answer"] }, as: :json
    assert_response :success
    assert response.parsed_body.fetch("correct")
    assert response.parsed_body.fetch("meaning").fetch("emoji").present?
  end

  test "memorize rejects missing stale and wrong kind identifiers" do
    post memorize_practice_session_path(@session), params: {}, as: :json
    assert_response :unprocessable_entity
    post memorize_practice_session_path(@session), params: { exercise_id: @session.exercises.last["id"] }, as: :json
    assert_response :conflict
    @session.update!(cursor: 0)
    post memorize_practice_session_path(@session), params: { exercise_id: @session.current_exercise["id"] }, as: :json
    assert_response :unprocessable_entity
    post memorize_practice_session_path(id: 9_999_999), params: { exercise_id: @exercise["id"] }, as: :json
    assert_response :not_found
    assert_equal 0, @session.reload.cursor
    assert_equal 0, @session.attempts.count
  end
end
