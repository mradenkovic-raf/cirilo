require "test_helper"

class BattlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @learner = Learner.current
    @session = @learner.practice_sessions.create!(status: "completed", completed_at: Time.current)
  end

  test "completed mission starts once and its battle survives a page refresh" do
    post practice_session_battle_path(@session)
    battle = @session.reload.battle
    assert_not_nil battle
    assert_redirected_to battle_path(battle)
    assert_response :see_other
    post practice_session_battle_path(@session)
    assert_redirected_to battle_path(battle)
    assert_equal 1, @learner.battles.count
    2.times do
      get battle_path(battle)
      assert_response :success
    end
    assert_equal 0, battle.reload.round
  end

  test "an active mission cannot unlock a battle" do
    active = @learner.practice_sessions.create!
    post practice_session_battle_path(active)
    assert_redirected_to practice_session_path(active)
    assert_equal 0, @learner.battles.count
  end

  test "armor icons are lost before hearts and the damage explanation survives refresh" do
    @learner.part_unlocks.create!(practice_session: @session, position: 1,
      part_key: Curriculum.part_at(1).fetch("id"))
    battle = BattleArena.start!(@learner, @session)
    arena = BattleArena.new(battle, enemy_picker: -> { "guard" })

    get battle_path(battle)
    assert_select '[data-hearts="player"] .heart-pip.is-full', 3
    assert_select '[data-armor="player"] .armor-pip.is-full svg', 1
    assert_select '[data-armor="player"] i', 0
    assert_select '[data-no-armor="player"][hidden]', 1

    arena.move!(move: "attack", expected_round: battle.round)
    get battle_path(battle)
    assert_select '[data-hearts="player"] .heart-pip.is-full', 3
    assert_select '[data-armor="player"] .armor-pip.is-full', 0
    assert_select '[data-no-armor="player"]:not([hidden])', text: "Без оклопа"
    assert_select '[data-result-detail]', text: "Клик губи део оклопа."

    arena.move!(move: "attack", expected_round: battle.round)
    get battle_path(battle)
    assert_select '[data-hearts="player"] .heart-pip.is-full', 2
    assert_select '[data-hearts="player"] .heart-pip:not(.is-full)', 1
    assert_select '[data-result-detail]', text: "Клик губи срце."
    assert_equal 1, @learner.part_unlocks.count
  end

  test "a battle without equipment shows no pretend armor icon" do
    battle = BattleArena.start!(@learner, @session)
    get battle_path(battle)
    %w[player enemy].each do |side|
      assert_select "[data-hearts=#{side}] .heart-pip.is-full", 3
      assert_select "[data-armor=#{side}] .armor-pip", 0
      assert_select "[data-no-armor=#{side}]:not([hidden])", text: "Без оклопа"
    end
  end

  test "finished battles keep the distinct outcome and hide round controls after refresh" do
    { "won" => ["feint", "Победа!", "Медаља је твоја!"],
      "lost" => ["guard", "Мргуд је победио.", "Нова мисија, нова шанса!"] }.each do |status, (enemy_move, title, detail)|
      mission = @learner.practice_sessions.create!(status: "completed", completed_at: Time.current)
      battle = BattleArena.start!(@learner, mission)
      arena = BattleArena.new(battle, enemy_picker: -> { enemy_move })
      3.times { arena.move!(move: "attack", expected_round: battle.round) }
      assert_equal status, battle.reload.status
      before = [battle.round, @learner.reload.xp]

      2.times do
        get battle_path(battle)
        assert_response :success
        assert_select ".battle-root.is-completed", count: 1
        assert_select "[data-battle-finale]:not([hidden])", count: 1
        assert_select "[data-final-title]", text: title
        assert_select "[data-final-detail]", text: detail
        assert_select "[data-active-battle][hidden]", count: 1
        assert_select "[data-result-strip][hidden]", count: 1
        assert_select ".battle-finale-actions form[action=?]", practice_sessions_path, count: 1
        assert_equal before, [battle.reload.round, @learner.reload.xp]
      end
    end
  end

  test "move endpoint returns persistent health and art and does not repeat a move" do
    battle = BattleArena.start!(@learner, @session)
    post battle_moves_path(battle), params: { move: "attack", expected_round: 0 }, as: :json
    assert_response :success
    first = response.parsed_body
    assert first["success"]
    assert_equal 1, first["round"]
    assert_includes %w[win lose tie], first["outcome"]
    assert_includes first["player_svg"], "<svg"
    assert_includes first["enemy_svg"], "<svg"

    post battle_moves_path(battle), params: { move: "attack", expected_round: 0 }, as: :json
    assert_response :success
    assert response.parsed_body["duplicate"]
    assert_equal 1, battle.reload.round
    assert_equal first["player_hp"], response.parsed_body["player_hp"]
    assert_equal first["enemy_hp"], response.parsed_body["enemy_hp"]

    post battle_moves_path(battle), params: { move: "guard", expected_round: 0 }, as: :json
    assert_response :conflict
    assert_equal 1, response.parsed_body.fetch("state").fetch("round")
    assert_includes response.parsed_body.fetch("state").fetch("player_svg"), "<svg"
  end

  test "malformed moves and rounds are rejected without advancing" do
    battle = BattleArena.start!(@learner, @session)
    [{}, { move: ["attack"], expected_round: 0 }, { move: "attack", expected_round: { value: 0 } },
      { move: "invented", expected_round: 0 }, { move: "attack", expected_round: -1 }].each do |values|
      post battle_moves_path(battle), params: values, as: :json
      assert_response :unprocessable_entity
      assert_not response.parsed_body["success"]
    end
    assert_equal 0, battle.reload.round
    assert_equal 0, @learner.reload.xp
  end

  test "unknown and foreign IDs cannot open or play another battle" do
    other = Learner.new(singleton_key: "test-other")
    other.save!(validate: false)
    foreign_session = other.practice_sessions.create!(status: "completed")
    foreign_battle = BattleArena.start!(other, foreign_session)
    post practice_session_battle_path(foreign_session)
    assert_response :not_found
    [foreign_battle.id, 9_999_999, "nonsense"].each do |id|
      get battle_path(id)
      assert_response :not_found
      post battle_moves_path(id), params: { move: "attack", expected_round: 0 }, as: :json
      assert_response :not_found
      post power_battle_path(id), params: { power: "goggles", expected_round: 0, expected_revision: 0 }, as: :json
      assert_response :not_found
    end
    post practice_session_battle_path("nonsense")
    assert_response :not_found
    assert_equal 0, foreign_battle.reload.round
  end

  test "power controls persist the reveal across refresh and repeat without another charge" do
    equip_powers
    battle = BattleArena.start!(@learner, @session)
    post power_battle_path(battle), params: { power: "goggles", expected_round: 0, expected_revision: 0 }, as: :json
    assert_response :success
    first = response.parsed_body
    assert_includes %w[attack guard feint], first["revealed_enemy_move"]
    assert_equal 1, first["action_revision"]
    assert_equal 0, first["round"]
    assert_includes first["player_svg"], "<svg"
    post power_battle_path(battle), params: { power: "goggles", expected_round: 0, expected_revision: 0 }, as: :json
    assert_response :success
    assert response.parsed_body["duplicate"]
    assert_equal first["revealed_enemy_move"], response.parsed_body["revealed_enemy_move"]
    get battle_path(battle)
    assert_response :success
    assert_select "[data-revealed-move]:not([hidden])", count: 1
    assert_select "[data-battle-power=goggles][disabled]", count: 1
    assert_select "[data-battle-power=shield]:not([disabled])", count: 1
    assert_select "[data-power-card]", count: 3
    assert_select "[data-revealed-name]", text: BattlesHelper::BATTLE_MOVE_NAMES[first["revealed_enemy_move"]]
    assert_select "[data-result-title]", text: "Наочаре су откриле потез!"

    post battle_moves_path(battle), params: { move: "attack", expected_round: 0, expected_revision: 0 }, as: :json
    assert_response :conflict
    assert_equal 1, response.parsed_body.fetch("state").fetch("action_revision")
  end

  test "power validation and unavailable gear do not alter the battle" do
    battle = BattleArena.start!(@learner, @session)
    [{}, { power: ["goggles"], expected_round: 0, expected_revision: 0 },
      { power: "shield", expected_round: 0 }, { power: "rockets", expected_round: 0, expected_revision: 0 }].each do |attributes|
      post power_battle_path(battle), params: attributes, as: :json
      assert_response :unprocessable_entity
    end
    assert_equal [0, 0, {}], battle.reload.values_at(:round, :action_revision, :power_state)
    get battle_path(battle)
    assert_select "[data-battle-power]", count: 0
    assert_select ".battle-powers", count: 0
    assert_select "[data-revealed-move][hidden]", count: 1
  end

  test "shield and rockets have distinct persistent controls and rocket round result renders" do
    equip_powers
    battle = BattleArena.start!(@learner, @session)
    post power_battle_path(battle), params: { power: "shield", expected_round: 0, expected_revision: 0 }, as: :json
    assert_response :success
    assert response.parsed_body["shield_armed"]
    post power_battle_path(battle), params: { power: "rockets", expected_round: 0, expected_revision: 1 }, as: :json
    assert_response :success
    assert_equal "dodge", response.parsed_body["outcome"]
    assert_equal 1, response.parsed_body["round"]
    assert response.parsed_body["shield_armed"]
    get battle_path(battle)
    assert_response :success
    assert_select "[data-shield-ready]:not([hidden])", count: 1
    assert_select "[data-battle-power=rockets][disabled]", count: 1
    assert_select "[data-result-title]", text: "Хоп! Клик је избегао потез."
  end

  private

  def equip_powers
    [7, 11, 12].each do |position|
      mission = @learner.practice_sessions.create!(status: "completed")
      @learner.part_unlocks.create!(practice_session: mission, position: position,
        part_key: Curriculum.part_at(position).fetch("id"))
    end
  end
end
