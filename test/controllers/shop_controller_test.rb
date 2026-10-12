require "test_helper"

class ShopControllerTest < ActionDispatch::IntegrationTest
  setup do
    @learner = test_learner
    @learner.update!(xp: 500)
  end

  test "catalog page renders and only the first paid purchase triggers unlock" do
    get shop_path
    assert_response :success
    assert_select "[data-shop-card]", ShopCatalog.items.length
    assert_select ".shop-next-choice #item-dino_tricera", 1
    assert_select "details.shop-later-drawer:not([open]) #item-dino_stego", 1
    assert_select "details.shop-choice-drawer:not([open]) #item-dino_rex", 1
    post shop_purchases_path, params: { item_id: "dino_tricera", price: -1000, xp: 100_000, shop_generation: 1 }
    assert_response :see_other
    assert_redirected_to shop_path(anchor: "shop-dino")
    assert_equal "dino_tricera", flash[:shop_unlock]
    assert_equal 260, @learner.reload.xp_balance
    assert_equal 500, @learner.xp
    follow_redirect!
    assert_response :success
    assert_select "[data-shop-card]", ShopCatalog.items.length
    assert_select ".shop-next-choice #item-dino_stego", 1
    assert_select ".shop-owned-grid #item-dino_tricera", 1

    post shop_purchases_path, params: { item_id: "dino_tricera", shop_generation: 1 }
    assert_response :see_other
    assert_nil flash[:shop_unlock]
    assert_equal 260, @learner.reload.xp_balance
    assert_equal 1, @learner.shop_purchases.count
  end

  test "unowned equipment and malformed purchases cannot bypass the catalog" do
    ["dino_robo", nil, ["dino_tricera"], { id: "dino_tricera", price: 0 }].each do |id|
      post shop_purchases_path, params: { item_id: id, shop_generation: 1 }
      assert_response :see_other
      assert_redirected_to(id == "dino_robo" ? shop_path(anchor: "shop-dino") : shop_path)
      assert flash[:alert].present?
    end
    patch equip_shop_path, params: { item_id: "dino_stego", shop_generation: 1 }
    assert_response :see_other
    assert_equal "rex", @learner.reload.selected_dino
    assert_equal 500, @learner.xp_balance
    assert_empty @learner.shop_purchases
  end

  test "free and bought choices equip without charging again including workshop color route" do
    patch equip_shop_path, params: { item_id: "color_blue", shop_generation: 1 }
    assert_response :see_other
    assert_equal "blue", @learner.reload.dino_color
    patch customize_workshop_path, params: { dino_color: "ice", shop_generation: 1 }
    assert_redirected_to workshop_path
    assert_equal "blue", @learner.reload.dino_color

    post shop_purchases_path, params: { item_id: "color_ice", shop_generation: 1 }
    assert_equal "ice", @learner.reload.dino_color
    patch customize_workshop_path, params: { dino_color: "peach", shop_generation: 1 }
    patch customize_workshop_path, params: { dino_color: "ice", shop_generation: 1 }
    assert_equal "ice", @learner.reload.dino_color
    assert_equal 380, @learner.xp_balance
    assert_equal 1, @learner.shop_purchases.count
  end

  test "generation is required on every purchase and equip route" do
    [nil, "", "01", "2", ["1"], { value: "1" }].each do |generation|
      post shop_purchases_path, params: { item_id: "dino_tricera", shop_generation: generation }
      assert_response :see_other
      assert_redirected_to shop_path(anchor: "shop-dino")
      assert flash[:alert].present?
      patch equip_shop_path, params: { item_id: "color_blue", shop_generation: generation }
      assert_response :see_other
      patch customize_workshop_path, params: { dino_color: "peach", shop_generation: generation }
      assert_response :see_other
    end
    assert_equal "green", @learner.reload.dino_color
    assert_equal 500, @learner.xp_balance
    assert_empty @learner.shop_purchases
  end

  test "forged direct requests cannot skip the shop sequence" do
    post shop_purchases_path, params: { item_id: "dino_stego", shop_generation: 1 }
    assert_response :see_other
    assert_redirected_to shop_path(anchor: "shop-dino")
    assert_includes flash[:alert], "Трицератопс"
    assert_equal 500, @learner.reload.xp_balance
    assert_empty @learner.shop_purchases
  end
end
