require "test_helper"
require_relative "exercise_helpers"

class EggCompanionTest < ActiveSupport::TestCase
  include ExerciseHelpers

  setup do
    @learner = test_learner
    @egg = EggCompanion.new(@learner)
  end

  test "only three newly completed missions hatch an egg and time never takes progress away" do
    @learner.update!(completed_missions: 10)
    assert_not @egg.chosen?
    assert @egg.choose!(species: "tricera", generation: 1)
    id = @egg.state.fetch("id")
    assert_equal 10, @egg.state.fetch("started_missions")
    assert_equal 0, @egg.stage
    assert_raises(EggCompanion::Error) { @egg.hatch!(egg_id: id) }

    3.times do |index|
      session = PracticePlanner.start!(@learner)
      solve_current_exercise(session)
      @learner.reload
      assert_equal index, @egg.stage, "a partial mission does not advance the egg"
      complete_practice_session(session)
      @learner.reload
      assert_equal index + 1, @egg.stage
      assert_equal index == 2, @egg.ready?
      travel 10.days do
        assert_equal index + 1, @egg.stage
      end
    end

    xp = @learner.xp
    assert @egg.hatch!(egg_id: id)
    assert @egg.hatched?
    assert_not @egg.ready?
    assert_not @egg.hatch!(egg_id: id)
    assert_equal xp, @learner.reload.xp
    assert @egg.name!(egg_id: id, name: "  Мали   Зуб  ")
    assert_equal "Мали Зуб", @egg.name
    assert_not @egg.name!(egg_id: id, name: "Мали Зуб")
    assert_raises(EggCompanion::Error) { @egg.name!(egg_id: id, name: "Друго име") }
    assert_equal xp, @learner.reload.xp
  end

  test "choice is permanent and malformed or stale choices cannot create an egg" do
    [nil, "", "robo", [], { "species" => "rex" }].each do |value|
      assert_raises(EggCompanion::Error) { @egg.choose!(species: value, generation: 1) }
    end
    [nil, "01", "1x", ["1"], { "version" => 1 }, 2].each do |generation|
      assert_raises(EggCompanion::Error) { @egg.choose!(species: "rex", generation: generation) }
    end
    assert_not @egg.chosen?
    assert @egg.choose!(species: "rex", generation: "1")
    before = @egg.state.deep_dup
    assert_not @egg.choose!(species: "rex", generation: 1)
    assert_raises(EggCompanion::Error) { @egg.choose!(species: "stego", generation: 1) }
    assert_equal before, @learner.reload.egg_state
    assert_equal [0, 0, "rex"], @learner.values_at(:xp, :xp_spent, :selected_dino)
  end

  test "invalid names and IDs cannot alter an egg and names are normalized" do
    @egg.choose!(species: "stego", generation: 1)
    id = @egg.state.fetch("id")
    assert_raises(EggCompanion::Error) { @egg.name!(egg_id: id, name: "Зубић") }
    @learner.update!(completed_missions: 3)
    @egg.hatch!(egg_id: id)
    before = @egg.state.deep_dup
    [nil, "", "  ", [], { "name" => "Зубић" }, "<script>", "123", "-", "а" * 21].each do |name|
      assert_raises(EggCompanion::Error) { @egg.name!(egg_id: id, name: name) }
    end
    [nil, "", [], { "id" => id }, SecureRandom.uuid].each do |wrong_id|
      assert_raises(EggCompanion::Error) { @egg.hatch!(egg_id: wrong_id) }
      assert_raises(EggCompanion::Error) { @egg.name!(egg_id: wrong_id, name: "Зубић") }
    end
    assert_equal before, @learner.reload.egg_state
    assert @egg.name!(egg_id: id, name: "Z\u030Cuti-Zub")
    assert_equal "Žuti-Zub", @egg.name
  end

  test "partial resets preserve the companion and full reset invalidates old forms" do
    @egg.choose!(species: "rex", generation: 1)
    id = @egg.state.fetch("id")
    complete_practice_session(PracticePlanner.start!(@learner))
    @learner.reload
    before = @egg.state.deep_dup
    DinoReset.reset!(@learner, confirmation: "1", generation: 1)
    ShopReset.reset!(@learner, confirmation: "1", reset_word: "RESET", generation: 1)
    assert_equal before, @learner.reload.egg_state
    assert_equal 1, @egg.stage

    FullReset.reset!(@learner, confirmation: "1", reset_word: "RESET", shop_generation: 2, dinosaur_generation: 2)
    assert_equal({}, @learner.reload.egg_state)
    assert_not @egg.chosen?
    assert_raises(EggCompanion::Error) { @egg.choose!(species: "rex", generation: 1) }
    assert_raises(EggCompanion::Error) { @egg.hatch!(egg_id: id) }
    assert_raises(EggCompanion::Error) { @egg.name!(egg_id: id, name: "Зубић") }
    @egg.choose!(species: "stego", generation: 3)
    assert_not_equal id, @egg.state.fetch("id")
    assert_equal 0, @egg.stage
    assert_raises(EggCompanion::Error) { @egg.hatch!(egg_id: id) }
  end
end
