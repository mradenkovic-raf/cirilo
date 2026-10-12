require "test_helper"

class ShopResetControllerTest < ActionDispatch::IntegrationTest
  setup do
    @learner = Learner.current
    @learner.update!(xp: 500)
    ShopService.new(@learner).purchase!(item_id: "color_ice")
  end

  test "parent economy reset requires explicit confirmation and typing" do
    get progress_path
    assert_response :success
    assert_select "form[action=?]", reset_shop_progress_path do
      assert_select "input[name=shop_generation][value='1']", 1
      assert_select "input[type=checkbox][name=confirm_reset][required]", 1
      assert_select "input[type=checkbox][name=confirm_reset][checked]", 0
      assert_select "input[name=reset_word][pattern=RESET][required]", 1
    end
    get workshop_path
    assert_response :success
    assert_select "form[action=?]", reset_shop_progress_path, count: 0
    [{}, { confirm_reset: "1", shop_generation: 1 },
      { reset_word: "RESET", shop_generation: 1 },
      { confirm_reset: "1", reset_word: "RESET", shop_generation: 2 }].each do |values|
      post reset_shop_progress_path, params: values
      assert_response :see_other
      assert_redirected_to progress_path
      assert flash[:alert].present?
      assert_equal 380, @learner.reload.xp_balance
      assert_equal 1, @learner.shop_purchases.count
    end
    post reset_shop_progress_path, params: { confirm_reset: "1", reset_word: "RESET", shop_generation: 1 }
    assert_response :see_other
    assert_redirected_to progress_path
    assert_equal 0, @learner.reload.xp_balance
    assert_equal 1, @learner.level
    assert_equal 2, @learner.shop_generation
    assert_empty @learner.shop_purchases
  end

  test "double reset and pre-reset browser forms cannot affect new progress" do
    post reset_shop_progress_path, params: { confirm_reset: "1", reset_word: "RESET", shop_generation: 1 }
    @learner.reload.update!(xp: 500)
    post shop_purchases_path, params: { item_id: "color_ice", shop_generation: 2 }
    assert_equal 380, @learner.reload.xp_balance
    post reset_shop_progress_path, params: { confirm_reset: "1", reset_word: "RESET", shop_generation: 1 }
    assert_response :see_other
    assert_equal 380, @learner.reload.xp_balance
    post shop_purchases_path, params: { item_id: "dino_tricera", shop_generation: 1 }
    patch equip_shop_path, params: { item_id: "color_blue", shop_generation: 1 }
    assert_equal 380, @learner.reload.xp_balance
    assert_equal "ice", @learner.dino_color
    assert_equal ["color_ice"], @learner.shop_purchases.pluck(:item_key)
  end
end
