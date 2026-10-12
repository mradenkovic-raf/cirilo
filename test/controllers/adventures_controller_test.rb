require "test_helper"
require_relative "../services/exercise_helpers"

class AdventuresControllerTest < ActionDispatch::IntegrationTest
  include ExerciseHelpers

  test "map visits are read only and show only the next playable step" do
    learner = Learner.current
    learner.update!(completed_missions: 9, xp: 185)
    before = [learner.xp, learner.completed_missions, learner.practice_sessions.count, learner.part_unlocks.count]
    2.times do
      get adventure_path
      assert_response :success
      assert_select ".adventure-world.is-completed", 2
      assert_select ".adventure-world.is-current#world-volcano", 1
      assert_select ".adventure-world.is-locked#world-space", 1
      assert_select ".adventure-step.is-completed", 9
      assert_select ".adventure-step.is-current", 1
      assert_select "form[action=?]", practice_sessions_path, 1
      assert_select "details.adventure-world:not([open])", 4
      assert_select ".adventure-step.is-locked form", 0
      assert_select ".adventure-world input[name='world']", 0
    end
    assert_equal before, [learner.reload.xp, learner.completed_missions, learner.practice_sessions.count, learner.part_unlocks.count]
  end

  test "map action resumes the existing mission instead of making a skipped one" do
    post practice_sessions_path
    session = Learner.current.active_session
    get adventure_path
    assert_response :success
    assert_select ".adventure-play", text: /Настави мисију/
    post practice_sessions_path
    assert_redirected_to practice_session_path(session)
    assert_equal 1, Learner.current.practice_sessions.count
    assert_equal 0, AdventureMap.new(Learner.current).completed_steps
  end

  test "actual mission completion advances map once and old result remains historical" do
    learner = Learner.current
    session = PracticePlanner.start!(learner)
    complete_practice_session(session)
    assert_equal 1, AdventureMap.new(learner.reload).completed_steps
    [adventure_path, practice_session_path(session), adventure_path].each do |path|
      get path
      assert_response :success
    end
    assert_equal 1, AdventureMap.new(learner.reload).completed_steps
    assert_equal 145, learner.xp
  end

  test "completed adventure keeps ordinary practice available without bonus claims" do
    learner = Learner.current
    learner.update!(completed_missions: 23)
    get adventure_path
    assert_response :success
    assert_select ".adventure-world.is-completed", 4
    assert_select ".adventure-step.is-current", 0
    assert_select ".adventure-play", text: /Вежбај даље/
    assert_select "form[action=?]", practice_sessions_path, 1
    assert_select "[role=progressbar][aria-valuenow='16']", 1
    get root_path
    assert_response :success
    assert_select ".home-adventure a[href=?]", adventure_path, 1
  end
end
