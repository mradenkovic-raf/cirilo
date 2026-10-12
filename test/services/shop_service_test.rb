require "test_helper"
require_relative "exercise_helpers"

class ShopServiceTest < ActiveSupport::TestCase
  include ExerciseHelpers

  setup do
    @learner = test_learner
    @learner.update!(xp: 1000)
    @shop = ShopService.new(@learner)
  end

  test "purchase spends only the wallet and equips the item permanently" do
    result = @shop.purchase!(item_id: "dino_tricera")
    assert result.fetch(:purchased)
    assert_equal "dino_tricera", result.fetch(:item).fetch("id")
    assert_equal 1000, @learner.reload.xp
    assert_equal 11, @learner.level
    assert_equal 240, @learner.xp_spent
    assert_equal 760, @learner.xp_balance
    assert_equal "tricera", @learner.selected_dino
    assert @learner.owns_shop_item?("dino_tricera")
    assert @learner.selected_shop_item?(ShopCatalog.find("dino_tricera"))
    assert_equal 240, @learner.shop_purchases.sole.price_paid
  end

  test "retrying purchase neither charges again nor overrides a later selection" do
    @shop.purchase!(item_id: "dino_tricera")
    @shop.equip!(item_id: "dino_rex")
    result = @shop.purchase!(item_id: "dino_tricera")
    assert_not result.fetch(:purchased)
    assert_equal "rex", @learner.reload.selected_dino
    assert_equal 240, @learner.xp_spent
    assert_equal 1, @learner.shop_purchases.count
    @shop.equip!(item_id: "dino_tricera")
    assert_equal "tricera", @learner.reload.selected_dino
    assert_equal 760, @learner.xp_balance
  end

  test "unaffordable and malformed purchases leave balance and selection untouched" do
    @learner.update!(xp: 239)
    assert_raises(ShopService::InsufficientFunds) { @shop.purchase!(item_id: "dino_tricera") }
    [nil, "", "missing", -1, ["dino_tricera"], { "id" => "dino_tricera", "price" => 0 }].each do |id|
      assert_raises(ShopService::InvalidItem) { @shop.purchase!(item_id: id) }
    end
    assert_equal 239, @learner.reload.xp_balance
    assert_equal "rex", @learner.selected_dino
    assert_empty @learner.shop_purchases
  end

  test "exact balance is enough and free choices need no purchase" do
    @learner.update!(xp: 120)
    @shop.purchase!(item_id: "color_ice")
    assert_equal 0, @learner.reload.xp_balance
    assert_equal "ice", @learner.dino_color
    ShopCatalog.items.select { |item| item.fetch("price").zero? }.each do |item|
      result = @shop.purchase!(item_id: item.fetch("id"))
      assert_not result.fetch(:purchased)
      assert @learner.selected_shop_item?(item)
    end
    assert_equal 120, @learner.reload.xp_spent
    assert_equal 1, @learner.shop_purchases.count
  end

  test "a failed learner save rolls back both the purchase and its charge" do
    @learner.update_columns(completed_missions: -1)
    assert_raises(ActiveRecord::RecordInvalid) { @shop.purchase!(item_id: "dino_tricera") }
    assert_equal 0, @learner.reload.xp_spent
    assert_equal 1000, @learner.xp_balance
    assert_equal "rex", @learner.selected_dino
    assert_empty @learner.shop_purchases
  end

  test "a child may equip only free or purchased choices in every category" do
    %w[dino_tricera color_ice theme_space effect_lightning].each do |id|
      assert_raises(ShopService::NotOwned) { @shop.equip!(item_id: id) }
      @shop.purchase!(item_id: id)
      assert @learner.selected_shop_item?(id)
      @shop.equip!(item_id: id)
    end
    assert_equal 260, @learner.reload.xp_balance
    assert_equal 4, @learner.shop_purchases.count
  end

  test "each paid category unlocks in order and requires every earlier purchase" do
    @learner.update!(xp: 4000)
    chains = [%w[dino_tricera dino_stego dino_robo], %w[color_ice color_lava color_cosmic],
      %w[theme_space theme_volcano theme_ocean], %w[effect_lightning effect_comets]]
    chains.each do |ids|
      assert_nil ShopCatalog.prerequisite_for(ids.first)
      assert_nil @learner.shop_requirement(ids.first)
      assert_equal ids[-2], ShopCatalog.prerequisite_for(ids.last).fetch("id")
      assert_equal ids.first, @learner.shop_requirement(ids.last).fetch("id")
      ids.drop(1).each do |id|
        assert_raises(ShopService::MissingRequirement) { @shop.purchase!(item_id: id) }
      end
      ids.each_with_index do |id, index|
        assert @shop.purchase!(item_id: id).fetch(:purchased)
        assert_nil @learner.shop_requirement(id)
        if index < ids.length - 1
          assert_equal ids[index + 1], @learner.shop_requirement(ids.last)&.fetch("id", nil) if index < ids.length - 2
          assert_nil @learner.shop_requirement(ids[index + 1])
        end
      end
    end
    assert_equal 11, @learner.shop_purchases.count
    assert_equal 1240, @learner.reload.xp_balance
    ShopCatalog.items.select { |item| item.fetch("price").zero? }.each do |item|
      assert_nil ShopCatalog.prerequisite_for(item)
      assert_nil @learner.shop_requirement(item)
    end
  end

  test "previously owned later choices remain usable without earlier purchases" do
    @learner.update!(xp: 2000, xp_spent: 1040)
    %w[dino_robo theme_ocean effect_comets].each do |id|
      item = ShopCatalog.find(id)
      @learner.shop_purchases.create!(item_key: id, price_paid: item.fetch("price"))
      assert_nil @learner.shop_requirement(item)
      assert_equal item, @shop.equip!(item_id: id)
      assert_not @shop.purchase!(item_id: id).fetch(:purchased)
    end
    assert_equal 1040, @learner.reload.xp_spent
    assert_equal "dino_tricera", @learner.shop_requirement("dino_stego").fetch("id")
    assert_raises(ShopService::MissingRequirement) { @shop.purchase!(item_id: "dino_stego") }
  end

  test "reset and restore keep bought items wallet and selected cosmetics" do
    %w[dino_tricera color_ice theme_space effect_lightning].each { |id| @shop.purchase!(item_id: id) }
    xp_before = [@learner.xp, @learner.xp_spent, @learner.xp_balance]
    bought = @learner.shop_purchases.order(:item_key).pluck(:item_key, :price_paid)
    DinoReset.reset!(@learner, confirmation: "1", generation: @learner.dinosaur_generation)
    assert_equal "green", @learner.reload.dino_color
    assert_equal ["tricera", "space", "lightning"], [@learner.selected_dino, @learner.selected_theme, @learner.selected_effect]
    assert_equal bought, @learner.shop_purchases.order(:item_key).pluck(:item_key, :price_paid)
    assert_equal xp_before, [@learner.xp, @learner.xp_spent, @learner.xp_balance]
    DinoReset.restore!(@learner, generation: @learner.dinosaur_generation)
    assert_equal "ice", @learner.reload.dino_color
    assert @learner.owns_shop_item?("color_ice")
    assert_equal xp_before, [@learner.xp, @learner.xp_spent, @learner.xp_balance]
  end

  test "learning fills the wallet and duplicate answers cannot farm spent XP back" do
    @shop.purchase!(item_id: "dino_tricera")
    session = PracticePlanner.start!(@learner)
    exercise = session.current_exercise
    result = solve_current_exercise(session)
    assert_equal 1010, result.fetch(:total_xp)
    assert_equal 770, result.fetch(:xp_balance)
    replay = AttemptRecorder.new(session).submit!(**correct_attributes(exercise))
    assert replay.fetch(:duplicate)
    assert_equal 0, replay.fetch(:xp_earned)
    assert_equal 770, replay.fetch(:xp_balance)
    complete_practice_session(session)
    assert_equal 1145, @learner.reload.xp
    assert_equal 905, @learner.xp_balance
    assert_equal 240, @learner.xp_spent
    battle = BattleArena.start!(@learner, session)
    assert_equal 4, battle.player_max_hp
    assert_equal 4, battle.enemy_max_hp
    BattleArena.new(battle, enemy_picker: -> { "feint" }).move!(move: "attack", expected_round: 0)
    assert_equal 905, @learner.reload.xp_balance
    assert_equal 1, @learner.part_unlocks.count
  end
end
