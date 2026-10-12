require "test_helper"

class AdventureMapTest < ActiveSupport::TestCase
  test "a new learner has only the first forest mission open" do
    map = map_at(0)
    assert_equal 0, map.rescued_count
    assert_equal [:current, :locked, :locked, :locked], map.worlds.map { |world| world[:state] }
    assert_equal 1, map.next_step[:number]
    assert_nil map.just_rescued_world
  end

  test "existing nine missions continue in the volcano without a reset" do
    map = map_at(9)
    assert_equal [:completed, :completed, :current, :locked], map.worlds.map { |world| world[:state] }
    assert_equal [4, 4, 1, 0], map.worlds.map { |world| world[:completed] }
    assert_equal 2, map.rescued_count
    assert_equal "volcano", map.current_world[:id]
    assert_equal 10, map.next_step[:number]
  end

  test "exactly one current node exists until the finite journey is complete" do
    (0..32).each do |count|
      map = map_at(count)
      states = map.worlds.flat_map { |world| world[:steps].map { |step| step[:state] } }
      assert_equal [count, 16].min, states.count(:completed), "count #{count}"
      assert_equal count < 16 ? 1 : 0, states.count(:current), "count #{count}"
      assert_equal [15 - count, 0].max, states.count(:locked), "count #{count}"
      assert_operator map.progress_percent, :<=, 100
    end
  end

  test "each fourth mission rescues the next friend once and later practice does not loop" do
    assert_equal %w[forest cave volcano space], [4, 8, 12, 16].map { |count| map_at(count).just_rescued_world[:id] }
    [0, 1, 3, 5, 9, 15, 17, 20, 100].each { |count| assert_nil map_at(count).just_rescued_world }
    map = map_at(100)
    assert map.completed?
    assert_equal 4, map.rescued_count
    assert_equal 16, map.completed_steps
    assert_nil map.current_world
    assert_nil map.next_step
  end

  test "historical mission progress is based on completion order not today's total" do
    learner = test_learner
    learner.update!(completed_missions: 9)
    now = Time.current
    old = learner.practice_sessions.create!(status: "completed", completed_at: now - 1.day)
    newer = learner.practice_sessions.create!(status: "completed", completed_at: now)
    same_time = learner.practice_sessions.create!(status: "completed", completed_at: now)
    assert_equal 1, AdventureMap.through(old).completed_steps
    assert_equal 2, AdventureMap.through(newer).completed_steps
    assert_equal 3, AdventureMap.through(same_time).completed_steps
    assert_equal 9, AdventureMap.new(learner).completed_steps
  end

  test "spending or resetting shop and gear does not rewind the journey" do
    learner = test_learner
    learner.update!(completed_missions: 9, xp: 500, xp_spent: 0, selected_theme: "meadow")
    ShopService.new(learner).purchase!(item_id: "theme_space", generation: learner.shop_generation)
    assert_equal 9, AdventureMap.new(learner.reload).completed_steps
    ShopReset.reset!(learner, confirmation: "1", reset_word: "RESET", generation: learner.shop_generation)
    completed = learner.practice_sessions.create!(status: "completed", completed_at: Time.current)
    learner.part_unlocks.create!(practice_session: completed, part_key: Curriculum.part_at(1).fetch("id"), position: 1)
    DinoReset.reset!(learner, confirmation: "1", generation: learner.dinosaur_generation)
    assert_equal 9, AdventureMap.new(learner.reload).completed_steps
    assert_equal 2, AdventureMap.new(learner).rescued_count
  end

  private

  def map_at(count)
    AdventureMap.new(Struct.new(:completed_missions).new(count))
  end
end
