require "test_helper"
require_relative "../services/exercise_helpers"

class MissionPathTest < ActionDispatch::IntegrationTest
  include ExerciseHelpers

  test "the mission path restores saved steps and shows the child's selected equipped dinosaur facing the arena" do
    learner = test_learner
    learner.update!(selected_dino: "stego", dino_color: "blue")
    complete_practice_session(PracticePlanner.start!(learner))
    session = PracticePlanner.start!(learner)
    3.times { solve_current_exercise(session) }

    get practice_session_path(session)
    assert_response :success
    assert_select "[data-mission-path][role=progressbar][aria-valuenow='3'][aria-valuemax='12']", 1
    assert_select "[data-mission-step]", 12
    assert_select ".mission-dot.is-done", 3
    assert_select ".mission-dino .dino-scene[aria-label*='Стегосаурус'][aria-label*='1 од']", 1
    assert_select ".mission-dino [fill='#79C7F3']", minimum: 1
    assert_select ".mission-villain .enemy-scene", 1
  end

  test "an incorrect answer inserts recovery without advancing the path and reload keeps the new total" do
    session = PracticePlanner.start!(test_learner)
    session.update!(exercises: [planned_exercise("read_word")] + session.exercises.drop(1))
    exercise = session.current_exercise
    wrong = exercise.fetch("options").find { |option| option != exercise.fetch("answer") }
    post practice_session_attempts_path(session), params: { exercise_id: exercise.fetch("id"), answer: wrong }, as: :json
    assert_response :success
    assert response.parsed_body.fetch("recovery_required")
    assert_equal 0, response.parsed_body.fetch("cursor")
    get practice_session_path(session)
    assert_response :success
    assert_select "[data-mission-path][aria-valuenow='0'][aria-valuemax='13']", 1
    assert_select "[data-mission-step]", 13
    assert_select ".mission-dot.is-done", 0
  end
end
