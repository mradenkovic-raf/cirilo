require "test_helper"
require_relative "../services/exercise_helpers"

class FullResetsControllerTest < ActionDispatch::IntegrationTest
  include ExerciseHelpers

  setup do
    @learner = test_learner
    @completed = complete_practice_session(PracticePlanner.start!(@learner))
    @battle = BattleArena.start!(@learner, @completed)
    @active = PracticePlanner.start!(@learner)
    @exercise = @active.current_exercise
    @learner.reload.update!(xp: 500, completed_missions: 8)
    ShopService.new(@learner).purchase!(item_id: "color_ice", generation: 1)
  end

  test "only parent settings contain the explicit full restart with unique controls" do
    get progress_path
    assert_response :success
    assert_select "details.reset-all:not([open])" do
      assert_select "form[action=?]", reset_all_progress_path do
        assert_select "input[name=shop_generation][value='1']", 1
        assert_select "input[name=dinosaur_generation][value='1']", 1
        assert_select "input[type=checkbox][name=confirm_reset][required]", 1
        assert_select "input[type=checkbox][name=confirm_reset][checked]", 0
        assert_select "input[name=reset_word][pattern=RESET][required]", 1
      end
    end
    ids = css_select(".parent-controls [id]").map { |node| node["id"] }
    assert_equal ids.uniq, ids
    assert_select ".reset-shop", text: /Мапа и спасени другари остају/
    assert_select ".reset-dino", text: /Мапа и спасени другари остају/
    [root_path, workshop_path, adventure_path].each do |path|
      get path
      assert_response :success
      assert_select "form[action=?]", reset_all_progress_path, count: 0
    end
  end

  test "incomplete confirmation cannot wipe data and a valid restart resets the map and friends" do
    [{}, { confirm_reset: "1" }, { reset_word: "RESET" },
      { confirm_reset: "1", reset_word: "RESET", shop_generation: 1 },
      { confirm_reset: "1", reset_word: "RESET", shop_generation: 1, dinosaur_generation: 2 }].each do |values|
      post reset_all_progress_path, params: values
      assert_response :see_other
      assert_redirected_to progress_path
      assert flash[:alert].present?
      assert_equal [380, 8, 1], [@learner.reload.xp_balance, @learner.completed_missions, @learner.shop_purchases.count]
    end
    post reset_all_progress_path, params: valid_params
    assert_response :see_other
    assert_redirected_to progress_path
    assert_equal [0, 0, 0], @learner.reload.values_at(:xp, :xp_spent, :completed_missions)
    assert_equal 0, AdventureMap.new(@learner).rescued_count
    assert_equal 1, AdventureMap.new(@learner).next_step.fetch(:number)
    follow_redirect!
    assert_response :success
    assert_select "form[action=?] input[name=shop_generation][value='2']", reset_all_progress_path, count: 1
    assert_select "form[action=?]", restore_dino_workshop_path, count: 0
  end

  test "deleted mission and battle URLs fail safely and cannot award points again" do
    post reset_all_progress_path, params: valid_params
    get practice_session_path(@active)
    assert_response :not_found
    post practice_session_attempts_path(@active), params: correct_attributes(@exercise), as: :json
    assert_response :not_found
    post memorize_practice_session_path(@active), params: { exercise_id: @exercise.fetch("id") }, as: :json
    assert_response :not_found
    post practice_session_battle_path(@completed)
    assert_response :not_found
    get battle_path(@battle)
    assert_response :not_found
    post battle_moves_path(@battle), params: { move: "attack", expected_round: 0 }, as: :json
    assert_response :not_found
    post power_battle_path(@battle), params: { power: "goggles", expected_round: 0, expected_revision: 0 }, as: :json
    assert_response :not_found
    assert_equal [0, 0], @learner.reload.values_at(:xp, :completed_missions)
    assert_empty @learner.practice_sessions
    assert_empty @learner.battles
    post practice_sessions_path
    assert_response :see_other
    assert_equal 1, @learner.practice_sessions.count
  end

  test "a replayed full restart does not delete progress earned after the restart" do
    post reset_all_progress_path, params: valid_params
    fresh = PracticePlanner.start!(@learner.reload)
    solve_current_exercise(fresh)
    post reset_all_progress_path, params: valid_params
    assert_response :see_other
    assert flash[:alert].present?
    assert_equal 10, @learner.reload.xp
    assert_equal 1, @learner.practice_sessions.count
    assert_equal 1, fresh.reload.cursor
  end

  private

  def valid_params
    { confirm_reset: "1", reset_word: "RESET", shop_generation: "1", dinosaur_generation: "1" }
  end
end
