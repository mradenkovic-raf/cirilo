require "test_helper"

class DinoResetControllerTest < ActionDispatch::IntegrationTest
  setup do
    @learner = Learner.current
    @learner.update!(xp: 125, completed_missions: 1, dino_color: "peach")
    @completed = @learner.practice_sessions.create!(status: "completed", completed_at: Time.current)
    @learner.part_unlocks.create!(practice_session: @completed, part_key: "boots", position: 1)
  end

  test "parent control requires an unchecked explicit confirmation and a generation token" do
    get progress_path
    assert_response :success
    assert_select "details.parent-reset.reset-dino" do
      assert_select "form[action=?]", reset_dino_workshop_path do
        assert_select "input[type=checkbox][name=confirm_reset][required]", 1
        assert_select "input[type=checkbox][name=confirm_reset][checked]", 0
        assert_select "input[name=dinosaur_generation][value='1']", 1
      end
    end
    assert_equal 1, @learner.part_unlocks.count
    get workshop_path
    assert_response :success
    assert_select "details.parent-reset", 0
    assert_select "form[action=?]", reset_dino_workshop_path, count: 0
  end

  test "missing or malformed confirmation cannot reset a collection" do
    [{}, { confirm_reset: "0", dinosaur_generation: "1" },
      { confirm_reset: ["1"], dinosaur_generation: "1" },
      { confirm_reset: "1", dinosaur_generation: { bad: "1" } }].each do |values|
      post reset_dino_workshop_path, params: values
      assert_redirected_to workshop_path
      assert_response :see_other
      assert_equal 1, @learner.part_unlocks.count
      assert_equal "peach", @learner.reload.dino_color
    end
  end

  test "reset and restore use HTML redirects and keep learning totals" do
    post reset_dino_workshop_path, params: { confirm_reset: "1", dinosaur_generation: "1" }
    assert_redirected_to workshop_path
    assert_response :see_other
    assert_equal 0, @learner.part_unlocks.count
    assert_equal 125, @learner.reload.xp
    assert_equal 1, @learner.completed_missions
    follow_redirect!
    assert_response :success
    get progress_path
    assert_response :success
    assert_select "form[action=?]", restore_dino_workshop_path, count: 1

    post restore_dino_workshop_path, params: { dinosaur_generation: "2" }
    assert_redirected_to workshop_path
    assert_equal 1, @learner.part_unlocks.count
    assert_equal "peach", @learner.reload.dino_color
    assert_equal 125, @learner.xp
  end

  test "a duplicate reset request does not reset the new generation again" do
    2.times do
      post reset_dino_workshop_path, params: { confirm_reset: "1", dinosaur_generation: "1" }
      assert_redirected_to workshop_path
    end
    assert_equal 2, @learner.reload.dinosaur_generation
    assert_equal 1, @learner.last_dino_snapshot.fetch("unlocks").size
  end
end
