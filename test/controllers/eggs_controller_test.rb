require "test_helper"

class EggsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @learner = Learner.current
  end

  test "choosing hatching and naming redirect to the companion and celebrate once" do
    post egg_workshop_path, params: { species: "tricera", shop_generation: "1" }
    assert_response :see_other
    assert_redirected_to workshop_path(anchor: "egg")
    id = @learner.reload.egg_state.fetch("id")
    assert_equal "tricera", @learner.egg_state.fetch("species")
    @learner.update!(completed_missions: 3)

    post hatch_egg_workshop_path, params: { egg_id: id }
    assert_response :see_other
    assert_equal id, flash[:egg_hatched]
    assert @learner.reload.egg_state.fetch("hatched")
    post hatch_egg_workshop_path, params: { egg_id: id }
    assert_response :see_other
    assert_nil flash[:egg_hatched]

    patch name_egg_workshop_path, params: { egg_id: id, name: "  Зубић  " }
    assert_response :see_other
    assert_redirected_to workshop_path(anchor: "egg")
    assert_equal "Зубић", @learner.reload.egg_state.fetch("name")
    assert_equal 0, @learner.xp
  end

  test "invalid requests show an error instead of changing progress or failing" do
    [nil, [], { species: "rex" }, "bad"].each do |species|
      post egg_workshop_path, params: { species: species, shop_generation: "1" }
      assert_response :see_other
      assert flash[:alert].present?
      assert_equal({}, @learner.reload.egg_state)
    end
    post egg_workshop_path, params: { species: "rex", shop_generation: "1" }
    id = @learner.reload.egg_state.fetch("id")
    post hatch_egg_workshop_path, params: { egg_id: id }
    assert_response :see_other
    assert flash[:alert].present?
    assert_not @learner.reload.egg_state.fetch("hatched")
    @learner.update!(completed_missions: 3)
    post hatch_egg_workshop_path, params: { egg_id: id }
    patch name_egg_workshop_path, params: { egg_id: id, name: ["Зубић"] }
    assert_response :see_other
    assert flash[:alert].present?
    assert_equal "", @learner.reload.egg_state.fetch("name")
    assert_equal 0, @learner.xp
  end

  test "workshop renders each stage and the hatch celebration appears only once" do
    get workshop_path
    assert_response :success
    assert_select "#egg[data-egg-stage=choose] .egg-choice", 3
    post egg_workshop_path, params: { species: "rex", shop_generation: "1" }
    id = @learner.reload.egg_state.fetch("id")

    4.times do |stage|
      @learner.update!(completed_missions: stage)
      get workshop_path
      assert_response :success
      assert_select "#egg[data-egg-stage='#{stage}']", 1
      assert_select "#egg [role=progressbar][aria-valuenow='#{stage}']", 1
      assert_select "#egg form[action=?]", hatch_egg_workshop_path, count: stage == 3 ? 1 : 0
      assert_select "#egg form[action=?]", name_egg_workshop_path, count: 0
    end

    post hatch_egg_workshop_path, params: { egg_id: id }
    follow_redirect!
    assert_response :success
    assert_select "#egg[data-egg-hatched]", 1
    assert_select "#egg form[action=?]", name_egg_workshop_path, count: 1
    get workshop_path
    assert_select "#egg[data-egg-hatched]", 0
    patch name_egg_workshop_path, params: { egg_id: id, name: "Зубић" }
    follow_redirect!
    assert_response :success
    assert_select "#egg-title", text: "Зубић"
    assert_select "#egg form", 0

    post reset_all_progress_path, params: { confirm_reset: "1", reset_word: "RESET", shop_generation: "1", dinosaur_generation: "1" }
    assert_response :see_other
    get workshop_path
    assert_select "#egg[data-egg-stage=choose] .egg-choice", 3
    patch name_egg_workshop_path, params: { egg_id: id, name: "Стари другар" }
    assert_response :see_other
    assert flash[:alert].present?
    assert_equal({}, @learner.reload.egg_state)
  end
end
