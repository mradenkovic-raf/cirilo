require "test_helper"

class BattleSpeciesSnapshotTest < ActiveSupport::TestCase
  setup do
    @learner = Learner.current
    @learner.update!(xp: 5_000)
    @shop = ShopService.new(@learner)
    @renderer = Object.new.extend(ApplicationHelper).extend(DinoHelper).extend(BattlesHelper)
    2.times do |index|
      @learner.part_unlocks.create!(practice_session: completed_session,
        part_key: Curriculum.part_at(index + 1).fetch("id"), position: index + 1)
    end
  end

  test "equipping another shop dinosaur and color cannot change an existing battle" do
    @shop.purchase!(item_id: "dino_tricera")
    @shop.purchase!(item_id: "color_ice")
    session = completed_session
    battle = BattleArena.start!(@learner, session)
    assert_equal ["tricera", "ice"], battle.values_at(:dino_species, :dino_color)

    @shop.purchase!(item_id: "dino_stego")
    @shop.purchase!(item_id: "dino_robo")
    @shop.purchase!(item_id: "color_lava")
    assert_equal ["robo", "lava"], @learner.reload.values_at(:selected_dino, :dino_color)
    state = BattleArena.new(battle, enemy_picker: -> { "guard" }).move!(move: "attack", expected_round: 0)
    assert_equal "tricera", state.fetch(:dino_species)
    assert_equal "ice", state.fetch(:dino_color)
    assert_equal 1, state.fetch(:armor_remaining)
    svg = @renderer.battle_player_svg(state)
    assert_includes svg, 'data-dino-species="tricera"'
    assert_includes svg, "#B6EBF2"
    assert_not_includes svg, 'data-dino-species="robo"'
    assert_equal battle.id, BattleArena.start!(@learner, session).id

    new_battle = BattleArena.start!(@learner, completed_session)
    assert_equal ["robo", "lava"], new_battle.values_at(:dino_species, :dino_color)
    assert_equal ["tricera", "ice"], battle.reload.values_at(:dino_species, :dino_color)
    assert_equal 2, @learner.part_unlocks.count
  end

  test "new species keep their snapshot after reload and do not change the default rex" do
    assert_equal "rex", Battle.new.dino_species
    assert_equal @renderer.dino_svg, @renderer.dino_svg(species: "rex")
    @shop.purchase!(item_id: "dino_tricera")
    @shop.purchase!(item_id: "dino_stego")
    @shop.purchase!(item_id: "color_ice")
    @shop.purchase!(item_id: "color_lava")
    @shop.purchase!(item_id: "color_cosmic")
    battle = BattleArena.start!(@learner, completed_session)
    state = BattleArena.state(Battle.find(battle.id))
    assert_equal "stego", state.fetch(:dino_species)
    assert_equal "cosmic", state.fetch(:dino_color)
    svg = @renderer.battle_player_svg(state)
    assert_includes svg, 'data-dino-species="stego"'
    assert_includes svg, "#BEA0EC"
    assert_includes svg, "#E7F2E2"
  end

  private

  def completed_session
    @learner.practice_sessions.create!(status: "completed", completed_at: Time.current)
  end
end
