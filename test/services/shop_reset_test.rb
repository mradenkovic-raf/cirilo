require "test_helper"
require_relative "exercise_helpers"

class ShopResetTest < ActiveSupport::TestCase
  include ExerciseHelpers

  setup do
    @learner = test_learner
    @learner.update!(xp: 3000, completed_missions: 1)
    @shop = ShopService.new(@learner)
    %w[dino_tricera color_ice theme_space effect_lightning].each do |id|
      @shop.purchase!(item_id: id, generation: 1)
    end
    @completed = @learner.practice_sessions.create!(status: "completed", completed_at: Time.current)
    @learner.part_unlocks.create!(practice_session: @completed, part_key: "boots", position: 1)
    @battle = BattleArena.start!(@learner, @completed)
    @active = PracticePlanner.start!(@learner)
    @old_exercise = @active.current_exercise
    solve_current_exercise(@active)
  end

  test "economy reset clears XP and purchases while preserving learning gear and battles" do
    history = learning_history
    reset_shop
    assert_equal [0, 0, 0, 1], [@learner.xp, @learner.xp_spent, @learner.xp_balance, @learner.level]
    assert_equal ["rex", "green", "meadow", "stars"],
      @learner.values_at(:selected_dino, :dino_color, :selected_theme, :selected_effect)
    assert_equal 2, @learner.shop_generation
    assert_empty @learner.shop_purchases
    assert_equal history, learning_history
    assert_equal ["tricera", "ice"], @battle.reload.values_at(:dino_species, :dino_color)

    replay = AttemptRecorder.new(@active).submit!(**correct_attributes(@old_exercise))
    assert replay.fetch(:duplicate)
    assert_equal 0, replay.fetch(:xp_balance)
    assert_equal 0, replay.fetch(:xp_earned)
    solve_current_exercise(@active)
    assert_equal 10, @learner.reload.xp_balance
  end

  test "checkbox typed RESET and exact generation are all required" do
    before = [@learner.reload.attributes, @learner.shop_purchases.map(&:attributes)]
    [{ confirmation: nil }, { confirmation: true }, { confirmation: ["1"] },
      { reset_word: nil }, { reset_word: "reset" }, { reset_word: " RESET " }, { reset_word: ["RESET"] },
      { generation: nil }, { generation: 0 }, { generation: "01" }, { generation: 1.0 },
      { generation: ["1"] }, { generation: { current: "1" } }, { generation: 2 }].each do |change|
      values = { confirmation: "1", reset_word: "RESET", generation: "1" }.merge(change)
      assert_raises(ShopReset::InvalidRequest) { ShopReset.reset!(@learner, **values) }
    end
    assert_equal before, [@learner.reload.attributes, @learner.shop_purchases.map(&:attributes)]
  end

  test "stale reset purchase and equip forms cannot change the new shop generation" do
    reset_shop
    @learner.update!(xp: 500)
    @shop.purchase!(item_id: "color_ice", generation: "2")
    assert_raises(ShopReset::InvalidRequest) { reset_shop(generation: 1) }
    assert_raises(ShopService::StaleRequest) { @shop.purchase!(item_id: "dino_tricera", generation: "1") }
    assert_raises(ShopService::StaleRequest) { @shop.equip!(item_id: "color_blue", generation: "1") }
    assert_equal 380, @learner.reload.xp_balance
    assert_equal "ice", @learner.dino_color
    assert_equal 2, @learner.shop_generation
    assert_equal ["color_ice"], @learner.shop_purchases.pluck(:item_key)
  end

  test "restoring saved gear cannot revive a paid color deleted by the economy reset" do
    DinoReset.reset!(@learner, confirmation: "1", generation: @learner.dinosaur_generation)
    assert_equal "ice", @learner.reload.last_dino_snapshot.fetch("dino_color")
    reset_shop
    assert @learner.can_restore_dino?
    DinoReset.restore!(@learner, generation: @learner.dinosaur_generation)
    assert_equal ["boots"], @learner.part_unlocks.pluck(:part_key)
    assert_equal "green", @learner.reload.dino_color
    assert_equal 0, @learner.xp_balance
    assert_not @learner.owns_shop_item?("color_ice")
  end

  test "a failed save rolls back deleted purchases and the generation" do
    @learner.update_columns(completed_missions: -1)
    bought = @learner.shop_purchases.order(:item_key).pluck(:item_key, :price_paid)
    xp_before = @learner.reload.xp
    assert_raises(ActiveRecord::RecordInvalid) { reset_shop }
    assert_equal 1, @learner.reload.shop_generation
    assert_equal xp_before, @learner.xp
    assert_equal bought, @learner.shop_purchases.order(:item_key).pluck(:item_key, :price_paid)
  end

  private

  def reset_shop(generation: @learner.shop_generation)
    ShopReset.reset!(@learner, confirmation: "1", reset_word: "RESET", generation: generation)
  end

  def learning_history
    [@learner.reload.completed_missions, @learner.letter_progresses.order(:id).map(&:attributes),
      @learner.practice_sessions.order(:id).map(&:attributes), @learner.attempts.order(:id).map(&:attributes),
      @learner.part_unlocks.order(:id).map(&:attributes), @learner.battles.order(:id).map(&:attributes)]
  end
end
