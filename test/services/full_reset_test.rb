require "test_helper"
require_relative "exercise_helpers"

class FullResetTest < ActiveSupport::TestCase
  include ExerciseHelpers

  CHILD_MODELS = [Attempt, Battle, PartUnlock, PracticeSession, LetterProgress, LetterConfusion, ShopPurchase].freeze

  setup do
    @learner = Learner.current
    @completed = complete_practice_session(PracticePlanner.start!(@learner))
    @learner.reload.update!(xp: 3000, completed_missions: 8)
    %w[dino_tricera color_ice theme_space effect_lightning].each do |item|
      ShopService.new(@learner).purchase!(item_id: item, generation: 1)
    end
    @battle = BattleArena.start!(@learner, @completed)
    @active = PracticePlanner.start!(@learner)
    solve_current_exercise(@active)
    @learner.letter_confusions.create!(expected_letter_id: "a", chosen_letter_id: "o",
      observations: 2, independent_successes: 1, last_mistake_at: Time.current)
  end

  test "full restart removes every progress record and returns the map to its first rescue" do
    id, created_at = @learner.id, @learner.created_at
    # Include a saved workshop collection, not just currently worn gear.
    @learner.update!(last_dino_snapshot: { "dino_color" => "ice", "unlocks" => [
      @learner.part_unlocks.first.attributes.slice(*DinoReset::UNLOCK_ATTRIBUTES)
    ] })
    CHILD_MODELS.each { |model| assert model.where(learner_id: id).exists?, model.name }
    # Previously loaded associations must not leave stale cards or statistics.
    @learner.practice_sessions.load
    @learner.part_unlocks.load
    @learner.shop_purchases.load

    reset_all

    assert_equal id, @learner.id
    assert_equal created_at, @learner.created_at
    assert_equal 1, Learner.count
    assert_equal [0, 0, 0], @learner.values_at(:xp, :xp_spent, :completed_missions)
    assert_equal ["rex", "green", "meadow", "stars"],
      @learner.values_at(:selected_dino, :dino_color, :selected_theme, :selected_effect)
    assert_equal [2, 2], @learner.values_at(:shop_generation, :dinosaur_generation)
    assert_equal({}, @learner.last_dino_snapshot)
    assert_not @learner.can_restore_dino?
    assert_nil @learner.active_session
    CHILD_MODELS.each { |model| assert_empty model.where(learner_id: id), model.name }
    map = AdventureMap.new(@learner)
    assert_equal 0, map.rescued_count
    assert_equal 0, map.completed_steps
    assert_equal 1, map.next_step.fetch(:number)
    assert_equal "forest", map.current_world.fetch(:id)
    assert_equal 1, @learner.level

    fresh = complete_practice_session(PracticePlanner.start!(@learner))
    assert_operator fresh.id, :>, @active.id
    assert_equal [145, 1], @learner.reload.values_at(:xp, :completed_missions)
    assert_equal "boots", fresh.part_unlock.part_key
    assert_equal 0, AdventureMap.new(@learner).rescued_count
  end

  test "confirmation word and both exact generations are mandatory" do
    before = snapshot
    changes = [{ confirmation: nil }, { confirmation: true }, { confirmation: ["1"] },
      { reset_word: nil }, { reset_word: "reset" }, { reset_word: " RESET " }, { reset_word: ["RESET"] }]
    [nil, 0, -1, "01", "1x", "2", 1.0, ["1"], { "version" => 1 }].each do |value|
      changes << { shop_generation: value } << { dinosaur_generation: value }
    end
    changes.each do |change|
      assert_raises(FullReset::InvalidRequest) { reset_all(**change) }
    end
    assert_equal before, snapshot
  end

  test "duplicate restart and old shop or dinosaur requests cannot change new progress" do
    reset_all
    @learner.update!(xp: 500)
    ShopService.new(@learner).purchase!(item_id: "color_ice", generation: 2)
    assert_raises(FullReset::InvalidRequest) { reset_all }
    assert_raises(ShopReset::InvalidRequest) do
      ShopReset.reset!(@learner, confirmation: "1", reset_word: "RESET", generation: 1)
    end
    assert_raises(ShopService::StaleRequest) { ShopService.new(@learner).purchase!(item_id: "dino_tricera", generation: 1) }
    assert_raises(ShopService::StaleRequest) { ShopService.new(@learner).equip!(item_id: "color_blue", generation: 1) }
    assert_raises(DinoReset::InvalidRequest) { DinoReset.reset!(@learner, confirmation: "1", generation: 1) }
    assert_raises(DinoReset::InvalidRequest) { DinoReset.restore!(@learner, generation: 1) }
    assert_raises(DinoReset::InvalidRequest) { DinoReset.restore!(@learner, generation: 2) }
    assert_equal [380, "ice", 2, 2], [@learner.reload.xp_balance, @learner.dino_color,
      @learner.shop_generation, @learner.dinosaur_generation]
  end

  test "forms opened before either partial reset cannot erase the subsequent state" do
    DinoReset.reset!(@learner, confirmation: "1", generation: 1)
    before = snapshot
    assert_raises(FullReset::InvalidRequest) { reset_all }
    assert_equal before, snapshot
    ShopReset.reset!(@learner, confirmation: "1", reset_word: "RESET", generation: 1)
    before = snapshot
    assert_raises(FullReset::InvalidRequest) { reset_all(dinosaur_generation: 2) }
    assert_equal before, snapshot
  end

  test "loaded old missions attempts and battles cannot recreate deleted state" do
    recorder = AttemptRecorder.new(@active)
    exercise = @active.reload.current_exercise
    arena = BattleArena.new(@battle)
    reset_all
    assert_raises(ActiveRecord::RecordNotFound) { recorder.submit!(**correct_attributes(exercise)) }
    assert_raises(ActiveRecord::RecordNotFound) { recorder.memorize!(exercise_id: exercise.fetch("id")) }
    assert_raises(ActiveRecord::RecordNotFound) { PracticePlanner.upgrade!(@active) }
    assert_raises(ActiveRecord::RecordNotFound) { BattleArena.start!(@learner, @completed) }
    assert_raises(ActiveRecord::RecordNotFound) { arena.move!(move: "attack", expected_round: 0) }
    assert_raises(ActiveRecord::RecordNotFound) { arena.power!(power: "goggles", expected_round: 0, expected_revision: 0) }
    assert_equal [0, 0], @learner.reload.values_at(:xp, :completed_missions)
    CHILD_MODELS.each { |model| assert_empty model.where(learner_id: @learner.id), model.name }
  end

  test "a failed save rolls back all child deletions and both generations" do
    @learner.update_columns(singleton_key: "invalid")
    before = snapshot
    assert_raises(ActiveRecord::RecordInvalid) { reset_all }
    assert_equal before, snapshot
  end

  private

  def reset_all(**changes)
    values = { confirmation: "1", reset_word: "RESET", shop_generation: 1, dinosaur_generation: 1 }.merge(changes)
    FullReset.reset!(@learner, **values)
  end

  def snapshot
    [@learner.reload.attributes, *CHILD_MODELS.map { |model| model.where(learner_id: @learner.id).order(:id).map(&:attributes) }]
  end
end
