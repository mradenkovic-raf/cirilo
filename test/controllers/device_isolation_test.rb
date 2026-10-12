require "test_helper"
require_relative "../services/exercise_helpers"

class DeviceIsolationTest < ActionDispatch::IntegrationTest
  include ExerciseHelpers

  setup do
    @first_browser, @first = new_browser
    @second_browser, @second = new_browser
  end

  test "starting and answering missions are independent even when a request names another learner" do
    @first_browser.post practice_sessions_path, params: { learner_id: @second.id }
    assert_equal 303, @first_browser.response.status
    first_mission = @first.practice_sessions.sole
    assert_empty @second.practice_sessions

    @second_browser.post practice_sessions_path
    assert_equal 303, @second_browser.response.status
    second_mission = @second.practice_sessions.sole
    second_before = learner_snapshot(@second)
    @first_browser.post practice_session_attempts_path(first_mission),
      params: correct_attributes(first_mission.current_exercise).merge(learner_id: @second.id), as: :json
    assert_equal 200, @first_browser.response.status
    assert @first_browser.response.parsed_body.fetch("correct")
    assert_equal 1, first_mission.reload.cursor
    assert_operator @first.reload.xp, :>, 0
    assert_equal second_before, learner_snapshot(@second)

    @first_browser.post practice_sessions_path
    @second_browser.post practice_sessions_path
    assert_equal 1, @first.practice_sessions.count
    assert_equal 1, @second.practice_sessions.count
    assert_not_equal first_mission.id, second_mission.id
    assert_equal 0, second_mission.reload.cursor
  end

  test "foreign mission battle and action ids return 404 without touching either learner" do
    mission = PracticePlanner.start!(@second)
    mission.update!(cursor: mission.exercises.index { |exercise| exercise.fetch("kind") == "memory_word" })
    completed = @second.practice_sessions.create!(status: "completed", completed_at: Time.current)
    @second.part_unlocks.create!(practice_session: completed, part_key: Curriculum.part_at(7).fetch("id"), position: 7)
    battle = BattleArena.start!(@second, completed)
    first_before = learner_snapshot(@first)
    second_before = learner_snapshot(@second)
    requests = [
      [:get, practice_session_path(mission), {}],
      [:post, memorize_practice_session_path(mission), { exercise_id: mission.current_exercise.fetch("id") }],
      [:post, practice_session_attempts_path(mission), correct_attributes(mission.current_exercise)],
      [:post, practice_session_battle_path(completed), {}],
      [:get, battle_path(battle), {}],
      [:post, battle_moves_path(battle), { move: "attack", expected_round: 0, expected_revision: 0 }],
      [:post, power_battle_path(battle), { power: "goggles", expected_round: 0, expected_revision: 0 }]
    ]
    requests.each do |method, path, params|
      @first_browser.public_send(method, path, params: params, as: :json)
      assert_equal 404, @first_browser.response.status, "#{method.upcase} #{path}"
      assert_equal first_before, learner_snapshot(@first)
      assert_equal second_before, learner_snapshot(@second)
    end

    @second_browser.post memorize_practice_session_path(mission),
      params: { exercise_id: mission.current_exercise.fetch("id") }, as: :json
    assert_equal 200, @second_browser.response.status
    assert mission.reload.current_exercise.fetch("memory_hidden")
    @second_browser.get battle_path(battle)
    assert_equal 200, @second_browser.response.status
    @second_browser.post power_battle_path(battle),
      params: { power: "goggles", expected_round: 0, expected_revision: 0 }, as: :json
    assert_equal 200, @second_browser.response.status
    assert_equal 1, battle.reload.action_revision
    assert_equal first_before, learner_snapshot(@first)
  end

  test "shop purchases equipment and customization belong only to the cookie owner" do
    @first.update!(xp: 700)
    @second.update!(xp: 450)
    second_before = learner_snapshot(@second)
    @first_browser.post shop_purchases_path,
      params: { item_id: "color_ice", shop_generation: 1, learner_id: @second.id }
    assert_equal 303, @first_browser.response.status
    @first_browser.post shop_purchases_path, params: { item_id: "dino_tricera", shop_generation: 1 }
    assert_equal 303, @first_browser.response.status
    @first_browser.patch equip_shop_path, params: { item_id: "color_blue", shop_generation: 1 }
    assert_equal 303, @first_browser.response.status
    @first_browser.patch customize_workshop_path, params: { dino_color: "ice", shop_generation: 1 }
    assert_equal 303, @first_browser.response.status
    assert_equal [340, "tricera", "ice"], [@first.reload.xp_balance, @first.selected_dino, @first.dino_color]
    assert_equal %w[color_ice dino_tricera], @first.shop_purchases.order(:item_key).pluck(:item_key)
    assert_equal second_before, learner_snapshot(@second)

    @second_browser.patch equip_shop_path, params: { item_id: "dino_tricera", shop_generation: 1 }
    @second_browser.patch customize_workshop_path, params: { dino_color: "ice", shop_generation: 1 }
    assert_equal second_before, learner_snapshot(@second)
  end

  test "egg progress hatching and naming remain local and foreign egg ids are rejected" do
    @first_browser.post egg_workshop_path, params: { species: "rex", shop_generation: 1 }
    @second_browser.post egg_workshop_path, params: { species: "stego", shop_generation: 1 }
    first_egg = @first.reload.egg_state.fetch("id")
    second_egg = @second.reload.egg_state.fetch("id")
    assert_not_equal first_egg, second_egg
    @first.update!(completed_missions: 3)
    first_before = learner_snapshot(@first)
    second_before = learner_snapshot(@second)

    @second_browser.post hatch_egg_workshop_path, params: { egg_id: first_egg }
    @second_browser.patch name_egg_workshop_path, params: { egg_id: first_egg, name: "Туђи" }
    assert_equal first_before, learner_snapshot(@first)
    assert_equal second_before, learner_snapshot(@second)

    @first_browser.post hatch_egg_workshop_path, params: { egg_id: first_egg }
    assert_equal 303, @first_browser.response.status
    @first_browser.patch name_egg_workshop_path, params: { egg_id: first_egg, name: "Зубић" }
    assert_equal 303, @first_browser.response.status
    assert_equal [true, "Зубић"], @first.reload.egg_state.values_at("hatched", "name")
    assert_equal second_before, learner_snapshot(@second)
    assert_equal 0, EggCompanion.new(@second.reload).stage
  end

  test "dinosaur reset and restoration leave the other browser intact" do
    populate_progress(@first)
    populate_progress(@second)
    second_before = learner_snapshot(@second)
    @first_browser.post reset_dino_workshop_path, params: { confirm_reset: "1", dinosaur_generation: 1 }
    assert_equal 303, @first_browser.response.status
    assert_empty @first.part_unlocks
    assert_equal 500, @first.reload.xp
    assert_equal second_before, learner_snapshot(@second)
    @first_browser.post restore_dino_workshop_path, params: { dinosaur_generation: 2 }
    assert_equal 303, @first_browser.response.status
    assert_equal 1, @first.part_unlocks.count
    assert_equal second_before, learner_snapshot(@second)
  end

  test "XP and shop reset clears only the current browser economy" do
    populate_progress(@first)
    populate_progress(@second)
    second_before = learner_snapshot(@second)
    @first_browser.post reset_shop_progress_path,
      params: { confirm_reset: "1", reset_word: "RESET", shop_generation: 1, learner_id: @second.id }
    assert_equal 303, @first_browser.response.status
    assert_equal [0, 0, "rex", "green"], @first.reload.values_at(:xp, :xp_spent, :selected_dino, :dino_color)
    assert_empty @first.shop_purchases
    assert_equal 1, @first.part_unlocks.count
    assert_equal 1, @first.letter_progresses.count
    assert_equal second_before, learner_snapshot(@second)
  end

  test "full restart clears only the cookie owner and preserves the identity for later visits" do
    populate_progress(@first)
    populate_progress(@second)
    second_before = learner_snapshot(@second)
    first_digest = @first.device_token_digest
    first_id = @first.id
    @first_browser.post reset_all_progress_path,
      params: { confirm_reset: "1", reset_word: "RESET", shop_generation: 1, dinosaur_generation: 1, learner_id: @second.id }
    assert_equal 303, @first_browser.response.status
    assert_equal [0, 0, 0, 2, 2], @first.reload.values_at(:xp, :xp_spent, :completed_missions, :shop_generation, :dinosaur_generation)
    assert_equal({}, @first.egg_state)
    assert_equal first_digest, @first.device_token_digest
    %i[practice_sessions attempts battles part_unlocks letter_progresses letter_confusions shop_purchases].each do |association|
      assert_empty @first.public_send(association)
    end
    assert_equal second_before, learner_snapshot(@second)
    assert_no_difference "Learner.count" do
      @first_browser.get root_path
      assert_equal 200, @first_browser.response.status
      @first_browser.post practice_sessions_path
      assert_equal 303, @first_browser.response.status
    end
    assert_equal first_id, @first.practice_sessions.sole.learner_id
    assert_equal second_before, learner_snapshot(@second)
  end

  private

  def new_browser
    browser = ActionDispatch::Integration::Session.new(Rails.application)
    before = Learner.pluck(:id)
    browser.get root_path
    assert_equal 200, browser.response.status
    assert browser.cookies[:cirilo_device].present?
    [browser, Learner.where.not(id: before).sole]
  end

  def learner_snapshot(learner)
    learner.reload.attributes.merge("associations" =>
      %i[practice_sessions attempts battles part_unlocks letter_progresses letter_confusions shop_purchases].to_h do |association|
        [association, learner.public_send(association).order(:id).map(&:attributes)]
      end)
  end

  def populate_progress(learner)
    learner.update!(xp: 500, completed_missions: 8)
    completed = learner.practice_sessions.create!(status: "completed", completed_at: Time.current)
    learner.attempts.create!(practice_session: completed, exercise_id: SecureRandom.uuid,
      letter_id: "a", kind: "trace", correct: true, score: 92)
    learner.part_unlocks.create!(practice_session: completed, part_key: Curriculum.part_at(1).fetch("id"), position: 1)
    learner.letter_progresses.create!(letter_id: "a", correct_count: 5, review_level: 2)
    learner.letter_confusions.create!(expected_letter_id: "a", chosen_letter_id: "m", observations: 2,
      last_mistake_at: Time.current)
    ShopService.new(learner).purchase!(item_id: "color_ice", generation: 1)
    EggCompanion.new(learner).choose!(species: "rex", generation: 1)
    BattleArena.start!(learner, completed)
  end
end
