require "test_helper"
require_relative "../services/exercise_helpers"

class WorkshopFriendsTest < ActionDispatch::IntegrationTest
  include ExerciseHelpers

  test "only friends rescued by four completed missions appear in the living scene" do
    learner = Learner.current
    [0, 3, 4, 7, 8, 10, 11, 12, 15, 16, 24].each do |missions|
      learner.update!(completed_missions: missions)
      get workshop_path
      assert_response :success
      count = [missions / 4, 4].min
      assert_select "button[data-rescued-friend]", count
      AdventureMap::WORLDS.each_with_index do |world, index|
        assert_select "button[data-rescued-friend=?]", world[:id], count: index < count ? 1 : 0
      end
      assert_select ".friends-home-count", text: /#{count}\s*\/ 4/
    end
  end

  test "each rescued friend has a different activity and an accessible greeting without reward requests" do
    learner = Learner.current
    learner.update!(completed_missions: 16, xp: 320)
    before = [learner.attributes, learner.practice_sessions.count, learner.part_unlocks.count]
    2.times do
      get workshop_path
      assert_response :success
      %w[friend-ball friend-crystals friend-tower friend-rocket].each { |activity| assert_select ".friends-scene .#{activity}", 1 }
      assert_select "button[data-rescued-friend][type=button][aria-label][data-friend-greeting]", 4
      assert_select ".friends-scene form, .friends-scene a", 0
      assert_select "[data-friend-message][aria-live=polite]", 1
      assert_select ".friends-home-complete[href=?]", adventure_path
      assert_select ".friends-home-next", 0
    end
    assert_equal before, [learner.reload.attributes, learner.practice_sessions.count, learner.part_unlocks.count]
  end

  test "empty and partial homes explain the next rescue without showing an unearned friend in the scene" do
    learner = Learner.current
    get workshop_path
    assert_select "[data-friend-message]", text: 'Додирни Клика.'
    assert_select ".friends-home-next[href=?]", adventure_path, text: /Лиско.*Још 4 мисије/m
    learner.update!(completed_missions: 11)
    get workshop_path
    assert_select ".friends-home-next[href=?]", adventure_path, text: /Жарко.*Још 1 мисија/m
    assert_select "[data-rescued-friend=volcano]", 0
  end

  test "the actual rescue result invites the child to visit their friend at home" do
    learner = Learner.current
    session = nil
    4.times { session = complete_practice_session(PracticePlanner.start!(learner)) }
    get practice_session_path(session)
    assert_response :success
    assert_select ".mission-adventure--rescue a[href=?]", workshop_path, text: /Чека те код Клика/
    get workshop_path
    assert_select "button[data-rescued-friend=forest]", 1
    assert_select "button[data-rescued-friend]", 1
  end
end
