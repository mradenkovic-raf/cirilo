require "test_helper"
require_relative "../services/exercise_helpers"

class RoadRunsControllerTest < ActionDispatch::IntegrationTest
  include ExerciseHelpers

  setup do
    @learner = test_learner
    @mission = PracticePlanner.start!(@learner)
  end

  test "six real answers lead through the drive and skip returns to the seventh task" do
    6.times { solve_current_exercise(@mission) }
    get practice_session_path(@mission)
    assert_redirected_to practice_session_drive_path(@mission)
    follow_redirect!
    assert_response :success
    assert_select '[data-dino-drive]', 1
    assert_select '[data-drive-start]', text: "Вози!"
    assert_select '[data-drive-hearts] span', 3
    post skip_practice_session_drive_path(@mission)
    assert_redirected_to practice_session_path(@mission)
    follow_redirect!
    assert_response :success
    assert_equal 6, @mission.reload.cursor
    assert_not @mission.drive_pending?
  end

  test "drive cannot start before halfway and its course survives reload" do
    post start_practice_session_drive_path(@mission), as: :json
    assert_response :unprocessable_entity
    assert_equal 0, RoadRun.count
    get practice_session_drive_path(@mission)
    assert_redirected_to practice_session_path(@mission)
    @mission.update!(cursor: 6)
    2.times do
      post start_practice_session_drive_path(@mission), as: :json
      assert_response :success
      assert_equal "active", response.parsed_body.dig("state", "status")
      assert_equal 11, response.parsed_body.dig("state", "obstacles").length
    end
    assert_equal 1, RoadRun.count
    get practice_session_drive_path(@mission)
    assert_response :success
    state = JSON.parse(css_select('[data-drive-state]').first.text)
    assert_equal @mission.reload.road_run.token, state.fetch("token")
  end

  test "JSON finish validates actual moves and returns a saved shield for the arena" do
    @mission.update!(cursor: 6)
    post start_practice_session_drive_path(@mission), as: :json
    state = response.parsed_body.fetch("state")
    lane = 1
    moves = state.fetch("obstacles").filter_map do |rock|
      next unless rock["lane"] == lane
      lane = lane == 0 ? 1 : lane - 1
      { at_ms: rock["at_ms"] - 500, lane: lane }
    end
    travel 25.seconds do
      2.times do
        post finish_practice_session_drive_path(@mission), params: { token: state.fetch("token"), moves: moves, elapsed_ms: 24_000 }, as: :json
        assert_response :success
        assert_equal "won", response.parsed_body.fetch("status")
        assert response.parsed_body.fetch("shield_earned")
        assert_equal practice_session_path(@mission), response.parsed_body.fetch("next_url")
      end
    end
    get practice_session_path(@mission)
    assert_response :success
    complete_practice_session(@mission)
    post practice_session_battle_path(@mission)
    follow_redirect!
    assert_response :success
    assert_select '[data-road-shield]:not([hidden])', text: /Штит из вожње.*чува 1 погодак/
  end

  test "foreign missions cannot be viewed started finished or skipped" do
    other = Learner.create!
    foreign = PracticePlanner.start!(other)
    foreign.update!(cursor: 6)
    run = DinoDrive.new(foreign).start!
    get practice_session_drive_path(foreign)
    assert_response :not_found
    [start_practice_session_drive_path(foreign), finish_practice_session_drive_path(foreign), skip_practice_session_drive_path(foreign)].each do |path|
      post path, params: { token: run.token, moves: [], elapsed_ms: 24_000 }, as: :json
      assert_response :not_found
    end
    assert_equal "active", run.reload.status
    assert_nil @mission.reload.road_run
  end

  test "malformed JSON does not crash or give a shield" do
    @mission.update!(cursor: 6)
    run = DinoDrive.new(@mission).start!
    ["bad", {}, [{ lane: 0, at_ms: "500" }], [nil]].each do |moves|
      post finish_practice_session_drive_path(@mission), params: { token: run.token, moves: moves, elapsed_ms: 24_000 }, as: :json
      assert_response :unprocessable_entity
    end
    assert_equal "active", run.reload.status
  end
end
