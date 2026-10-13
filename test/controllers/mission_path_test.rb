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
    assert_select "[data-mission-drive][data-step='6'][data-status=upcoming]", 1
    assert_select "[data-mission-path][aria-valuetext*='Вожња те чека']", 1
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
    assert_equal 7, response.parsed_body.fetch("drive_checkpoint").fetch("step")
    assert_equal "upcoming", response.parsed_body.fetch("drive_checkpoint").fetch("status")
    get practice_session_path(session)
    assert_response :success
    assert_select "[data-mission-path][aria-valuenow='0'][aria-valuemax='13']", 1
    assert_select "[data-mission-step]", 13
    assert_select ".mission-dot.is-done", 0
    assert_select "[data-mission-drive][data-step='7'][data-status=upcoming]", 1
  end

  test "the answer that reaches the drive checkpoint updates the live marker" do
    session = PracticePlanner.start!(test_learner)
    5.times { solve_current_exercise(session) }
    post practice_session_attempts_path(session), params: correct_attributes(session.reload.current_exercise), as: :json
    assert_response :success
    assert_equal({ "step" => 6, "status" => "current", "label" => "Време је за вожњу!" }, response.parsed_body.fetch("drive_checkpoint"))
    get practice_session_path(session)
    assert_redirected_to practice_session_drive_path(session)
  end

  test "the car shows a saved win loss or skip and stays before recovery tasks added later" do
    session = PracticePlanner.start!(test_learner)
    6.times { solve_current_exercise(session) }
    run = session.create_road_run!(status: "won", token: SecureRandom.hex(20))
    exercises = session.exercises.deep_dup
    exercises.insert(8, exercises.last.merge("id" => SecureRandom.uuid, "recovery_of" => exercises.last.fetch("id")))
    session.update!(exercises: exercises, cursor: 8)

    %w[won lost skipped].each do |status|
      run.update!(status: status)
      get practice_session_path(session)
      assert_response :success
      assert_select "[data-mission-drive][data-step='6'][data-status='#{status}']", 1
      assert_select "[data-mission-path][aria-valuenow='8'][aria-valuemax='13']", 1
    end
  end

  test "a mission played beyond the checkpoint without driving does not show an upcoming drive" do
    session = PracticePlanner.start!(test_learner)
    7.times { solve_current_exercise(session) }
    get practice_session_path(session)
    assert_response :success
    assert_select "[data-mission-drive][data-step='6'][data-status=passed]", 1
  end
end
